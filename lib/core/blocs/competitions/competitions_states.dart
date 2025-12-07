abstract class CompetitionsState {}

// Initial state
class CompetitionsInitial extends CompetitionsState {}

// ==================== Load Competitions States ====================
class LoadCompetitionsLoading extends CompetitionsState {}

class LoadCompetitionsSuccess extends CompetitionsState {}

class LoadCompetitionsError extends CompetitionsState {
  final String error;
  LoadCompetitionsError(this.error);
}

// ==================== Load Single Competition States ====================
class LoadCompetitionLoading extends CompetitionsState {}

class LoadCompetitionSuccess extends CompetitionsState {}

class LoadCompetitionError extends CompetitionsState {
  final String error;
  LoadCompetitionError(this.error);
}

// ==================== Create Competition States ====================
class CreateCompetitionLoading extends CompetitionsState {}

class CreateCompetitionSuccess extends CompetitionsState {
  final String competitionId;
  CreateCompetitionSuccess(this.competitionId);
}

class CreateCompetitionError extends CompetitionsState {
  final String error;
  CreateCompetitionError(this.error);
}

// ==================== Update Competition States ====================
class UpdateCompetitionLoading extends CompetitionsState {}

class UpdateCompetitionSuccess extends CompetitionsState {}

class UpdateCompetitionError extends CompetitionsState {
  final String error;
  UpdateCompetitionError(this.error);
}

// ==================== Delete Competition States ====================
class DeleteCompetitionLoading extends CompetitionsState {}

class DeleteCompetitionSuccess extends CompetitionsState {}

class DeleteCompetitionError extends CompetitionsState {
  final String error;
  DeleteCompetitionError(this.error);
}

// ==================== Upload Image States ====================
class UploadImageLoading extends CompetitionsState {}

class UploadImageSuccess extends CompetitionsState {
  final String imageUrl;
  UploadImageSuccess(this.imageUrl);
}

class UploadImageError extends CompetitionsState {
  final String error;
  UploadImageError(this.error);
}

// ==================== Search Competitions States ====================
class SearchCompetitionsLoading extends CompetitionsState {}

class SearchCompetitionsSuccess extends CompetitionsState {}

class SearchCompetitionsError extends CompetitionsState {
  final String error;
  SearchCompetitionsError(this.error);
}

// ==================== Filter Competitions States ====================
class FilterCompetitionsLoading extends CompetitionsState {}

class FilterCompetitionsSuccess extends CompetitionsState {}

class FilterCompetitionsError extends CompetitionsState {
  final String error;
  FilterCompetitionsError(this.error);
}

// ==================== Toggle Competition Status States ====================
class ToggleCompetitionStatusLoading extends CompetitionsState {}

class ToggleCompetitionStatusSuccess extends CompetitionsState {}

class ToggleCompetitionStatusError extends CompetitionsState {
  final String error;
  ToggleCompetitionStatusError(this.error);
}

// ==================== Submission States ====================
class SubmitAnswersLoading extends CompetitionsState {}

class SubmitAnswersSuccess extends CompetitionsState {
  final int score;
  final int totalPoints;
  SubmitAnswersSuccess(this.score, this.totalPoints);
}

class SubmitAnswersError extends CompetitionsState {
  final String error;
  SubmitAnswersError(this.error);
}

// ==================== Leaderboard States ====================
class LoadLeaderboardLoading extends CompetitionsState {}

class LoadLeaderboardSuccess extends CompetitionsState {}

class LoadLeaderboardError extends CompetitionsState {
  final String error;
  LoadLeaderboardError(this.error);
}

