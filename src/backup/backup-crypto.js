/**
 * KADAssist AP-BR02 browser-side backup encryption.
 * Password never leaves this browser module. No secrets are logged or persisted.
 * Envelope: magic "KADB", version=1, KDF=1 (PBKDF2-SHA-256), iterations uint32 BE,
 * salt 16 bytes, IV 12 bytes, followed by AES-256-GCM ciphertext+tag.
 */
const MAGIC = new Uint8Array([0x4b, 0x41, 0x44, 0x42]); // KADB
const VERSION = 1;
const KDF_PBKDF2_SHA256 = 1;
const ITERATIONS = 600_000;
const SALT_BYTES = 16;
const IV_BYTES = 12;
const HEADER_BYTES = 4 + 1 + 1 + 4 + SALT_BYTES + IV_BYTES;
const MIN_ITERATIONS = 200_000;
const MAX_ITERATIONS = 2_000_000;

export function validateBackupPassword(password) {
  if (typeof password !== "string") return { valid: false, reason: "password_type" };
  const bytes = new TextEncoder().encode(password);
  if (password.trim().length === 0) return { valid: false, reason: "empty" };
  if ([...password].length < 12) return { valid: false, reason: "minimum_length" };
  if (bytes.length > 1024) return { valid: false, reason: "maximum_bytes" };
  return { valid: true };
}

async function deriveKey(password, salt, iterations) {
  const material = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(password), "PBKDF2", false, ["deriveKey"]
  );
  return crypto.subtle.deriveKey(
    { name: "PBKDF2", hash: "SHA-256", salt, iterations },
    material,
    { name: "AES-GCM", length: 256 },
    false,
    ["encrypt", "decrypt"]
  );
}

function makeHeader(iterations, salt, iv) {
  const header = new Uint8Array(HEADER_BYTES);
  header.set(MAGIC, 0);
  header[4] = VERSION;
  header[5] = KDF_PBKDF2_SHA256;
  new DataView(header.buffer).setUint32(6, iterations, false);
  header.set(salt, 10);
  header.set(iv, 10 + SALT_BYTES);
  return header;
}

export async function encryptBackupBlob(inputBlob, password) {
  const validation = validateBackupPassword(password);
  if (!validation.valid) throw new Error("BACKUP_PASSWORD_" + validation.reason);
  if (!(inputBlob instanceof Blob)) throw new Error("BACKUP_INPUT_NOT_BLOB");
  if (!globalThis.crypto?.subtle) throw new Error("BACKUP_WEBCRYPTO_UNAVAILABLE");

  const salt = crypto.getRandomValues(new Uint8Array(SALT_BYTES));
  const iv = crypto.getRandomValues(new Uint8Array(IV_BYTES));
  const header = makeHeader(ITERATIONS, salt, iv);
  const key = await deriveKey(password, salt, ITERATIONS);
  const plaintext = await inputBlob.arrayBuffer();
  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv, additionalData: header, tagLength: 128 },
    key,
    plaintext
  );
  return new Blob([header, encrypted], { type: "application/vnd.kadassist.backup" });
}

export async function decryptBackupBlob(encryptedBlob, password) {
  const validation = validateBackupPassword(password);
  if (!validation.valid) throw new Error("BACKUP_PASSWORD_" + validation.reason);
  if (!(encryptedBlob instanceof Blob)) throw new Error("BACKUP_INPUT_NOT_BLOB");
  if (!globalThis.crypto?.subtle) throw new Error("BACKUP_WEBCRYPTO_UNAVAILABLE");

  const bytes = new Uint8Array(await encryptedBlob.arrayBuffer());
  if (bytes.length <= HEADER_BYTES + 16) throw new Error("BACKUP_ENVELOPE_TOO_SHORT");
  for (let i = 0; i < MAGIC.length; i++) if (bytes[i] !== MAGIC[i]) throw new Error("BACKUP_MAGIC_INVALID");
  if (bytes[4] !== VERSION || bytes[5] !== KDF_PBKDF2_SHA256) throw new Error("BACKUP_VERSION_UNSUPPORTED");

  const iterations = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).getUint32(6, false);
  if (iterations < MIN_ITERATIONS || iterations > MAX_ITERATIONS) throw new Error("BACKUP_KDF_PARAMETER_INVALID");
  const salt = bytes.slice(10, 10 + SALT_BYTES);
  const iv = bytes.slice(10 + SALT_BYTES, HEADER_BYTES);
  const header = bytes.slice(0, HEADER_BYTES);
  const key = await deriveKey(password, salt, iterations);
  const plaintext = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv, additionalData: header, tagLength: 128 },
    key,
    bytes.slice(HEADER_BYTES)
  );
  return new Blob([plaintext], { type: "application/zip" });
}

/** Decrypts locally, then extracts the package manifest only; never imports data. */
export async function readBackupManifestBlob(zipBlob) {
  if (!(zipBlob instanceof Blob)) throw new Error("BACKUP_ZIP_NOT_BLOB");
  const bytes = new Uint8Array(await zipBlob.arrayBuffer());
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let offset = 0;
  while (offset + 30 <= bytes.length) {
    const signature = view.getUint32(offset, true);
    if (signature !== 0x04034b50) {
      if (signature === 0x02014b50 || signature === 0x06054b50) break;
      offset++;
      continue;
    }
    const method = view.getUint16(offset + 8, true);
    const compressedSize = view.getUint32(offset + 18, true);
    const nameLength = view.getUint16(offset + 26, true);
    const extraLength = view.getUint16(offset + 28, true);
    const nameStart = offset + 30;
    const dataStart = nameStart + nameLength + extraLength;
    if (dataStart + compressedSize > bytes.length) throw new Error("BACKUP_ZIP_ENTRY_TRUNCATED");
    const name = new TextDecoder().decode(bytes.slice(nameStart, nameStart + nameLength));
    if (name === "manifest.json") {
      let content;
      const payload = bytes.slice(dataStart, dataStart + compressedSize);
      if (method === 0) content = payload;
      else if (method === 8 && typeof DecompressionStream !== "undefined") {
        const stream = new Blob([payload]).stream().pipeThrough(new DecompressionStream("deflate-raw"));
        content = new Uint8Array(await new Response(stream).arrayBuffer());
      } else throw new Error("BACKUP_ZIP_COMPRESSION_UNSUPPORTED");
      let manifest;
      try { manifest = JSON.parse(new TextDecoder().decode(content)); }
      catch { throw new Error("BACKUP_MANIFEST_INVALID"); }
      if (manifest?.format !== "KADAssist-Backup-Package" || !manifest?.scope || !manifest?.snapshot) throw new Error("BACKUP_MANIFEST_SCHEMA_INVALID");
      return manifest;
    }
    offset = dataStart + compressedSize;
  }
  throw new Error("BACKUP_MANIFEST_NOT_FOUND");
}
