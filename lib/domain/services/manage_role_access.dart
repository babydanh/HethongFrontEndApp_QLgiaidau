/// Role of the signed-in user on a tournament's management page, as answered
/// by the Backend (`data.manageRole` of `GET /tournaments/:id?manage=true`).
///
/// Managers (admin, creator, co-organizer, community manager) run everything;
/// an accepted tournament referee only operates matches.
enum ManageRole {
  manager,
  referee;

  /// Missing or empty means an older Backend that only lets managers in, so
  /// manager. Any value other than MANAGER fails closed to referee.
  static ManageRole fromApi(Object? raw) {
    if (raw == null) return manager;
    final value = raw.toString().trim().toUpperCase();
    if (value.isEmpty || value == 'MANAGER') return manager;
    return referee;
  }
}

/// Tabs of the management hub, in display order.
enum ManageHubTab {
  overview,
  divisions,
  athletes,
  bracket,
  schedule,
  results,
  camera,
  settings,
}

/// Write actions on the management page that depend on the role.
enum ManageAction {
  /// Tournament info, branding, contact, fee, lifecycle buttons, result
  /// reconfirmation and the overflow menu (exports, end, delete).
  editTournament,
  editDivisions,

  /// Add, import, pair, approve, kick, check in and edit athletes.
  editParticipants,

  /// Draw, seeds, group moves and stage operations.
  editBracket,

  /// Create courts and set court hours.
  manageCourts,

  /// Automatic/AI scheduling and its drafts.
  autoSchedule,

  /// Pick a match's referee (`refereeId`). The Backend rejects a referee's
  /// schedule write that carries `refereeId`, even null.
  assignReferee,

  /// Move or swap a match's time, court and duration on the schedule board.
  moveMatchSlot,

  /// Enter the score of a match that is not finalized (existing flow).
  scoreOpenMatch,
}

const _refereeTabs = [
  ManageHubTab.overview,
  ManageHubTab.divisions,
  ManageHubTab.athletes,
  ManageHubTab.bracket,
  ManageHubTab.schedule,
  ManageHubTab.results,
];

// Allow-list: an action added later stays manager-only for referees.
const _refereeActions = {
  ManageAction.moveMatchSlot,
  ManageAction.scoreOpenMatch,
};

List<ManageHubTab> visibleHubTabs(ManageRole role) =>
    role == ManageRole.manager ? ManageHubTab.values : _refereeTabs;

bool canManageAction(ManageRole role, ManageAction action) =>
    role == ManageRole.manager || _refereeActions.contains(action);
