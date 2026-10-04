class HelpRequest {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String userName;
  final String neighborhood;
  final double latitude;
  final double longitude;
  final String time;
  final bool isUrgent;
  final String status;
  final String? acceptedHelperId;
  final String? acceptedHelperName;

  const HelpRequest({
    required this.id,
    this.userId = '',
    required this.title,
    required this.description,
    required this.category,
    required this.userName,
    required this.neighborhood,
    required this.latitude,
    required this.longitude,
    required this.time,
    this.isUrgent = false,
    this.status = 'Ativo',
    this.acceptedHelperId,
    this.acceptedHelperName,
  });
}