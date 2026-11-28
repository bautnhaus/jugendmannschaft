/**
 * AP-BR02 RS03 – Restore authorization/scope contract.
 * Pure synthetic policy function. Inputs MUST be server-derived trusted grants
 * and server-validated active context; never pass manifest/client role claims.
 * No Supabase client, network, SQL, Storage or writes.
 */
export const RESTORE_SCOPE_DECISION = Object.freeze({
  ALLOW: "allow",
  DENY: "deny"
});

const deny = reason => ({decision:RESTORE_SCOPE_DECISION.DENY,reason});

export function authorizeRestoreScope({trustedActor,requestedScope,selectedContext,allowedCategories}) {
  if(!trustedActor || typeof trustedActor!=="object" ||
     !requestedScope || typeof requestedScope!=="object" ||
     !selectedContext || typeof selectedContext!=="object")
    return deny("TRUSTED_CONTEXT_MISSING");

  const categories=requestedScope.categories;
  if(!Array.isArray(categories)||categories.length===0||
     new Set(categories).size!==categories.length||
     !Array.isArray(allowedCategories)||
     categories.some(c=>!allowedCategories.includes(c)))
    return deny("CATEGORY_SELECTION_INVALID");

  const clubs=Array.isArray(trustedActor.clubIds)?trustedActor.clubIds.map(String):[];
  const teams=Array.isArray(trustedActor.teamIds)?trustedActor.teamIds.map(String):[];
  const clubTeams=trustedActor.clubTeamIds&&typeof trustedActor.clubTeamIds==="object"
    ? trustedActor.clubTeamIds : {};

  // Team scope: exactly one requested team and the currently verified context
  // must be that same team. No inferred team from a backup manifest.
  if(requestedScope.type==="team") {
    const id=String(requestedScope.id||"");
    const isSuper=trustedActor.isSuperAdmin===true;
    if(!id||(!isSuper&&!teams.includes(id))) return deny("TEAM_NOT_AUTHORIZED");
    if(selectedContext.type!=="team"||String(selectedContext.id||"")!==id)
      return deny("TEAM_CONTEXT_NOT_EXPLICIT");
    return {decision:RESTORE_SCOPE_DECISION.ALLOW,scope:{type:"team",id,categories:[...categories]}};
  }

  if(requestedScope.type==="club") {
    const id=String(requestedScope.id||"");
    const selectedTeams=requestedScope.teamIds;
    if(!id||!Array.isArray(selectedTeams)||selectedTeams.length===0||
       new Set(selectedTeams.map(String)).size!==selectedTeams.length)
      return deny("CLUB_SCOPE_SELECTION_INVALID");
    if(selectedContext.type!=="club"||String(selectedContext.id||"")!==id)
      return deny("CLUB_CONTEXT_NOT_EXPLICIT");

    const isSuper=trustedActor.isSuperAdmin===true;
    const isClubAdmin=clubs.includes(id);
    if(!isSuper&&!isClubAdmin) return deny("CLUB_NOT_AUTHORIZED");
    const teamsForClub=Array.isArray(clubTeams[id])?clubTeams[id].map(String):[];
    if(selectedTeams.some(teamId=>!teamsForClub.includes(String(teamId))))
      return deny("TEAM_OUTSIDE_SELECTED_CLUB");
    return {decision:RESTORE_SCOPE_DECISION.ALLOW,scope:{type:"club",id,teamIds:selectedTeams.map(String),categories:[...categories]}};
  }

  return deny("SCOPE_TYPE_NOT_ALLOWED");
}
