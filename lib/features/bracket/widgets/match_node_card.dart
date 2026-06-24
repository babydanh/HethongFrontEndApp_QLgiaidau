import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_detail.dart';

class MatchNodeCard extends StatelessWidget {
  final MatchModel match;
  final bool isReferee;
  final bool isReadOnly;
  final String tournamentId;
  final double width;

  const MatchNodeCard({
    super.key,
    required this.match,
    required this.isReferee,
    required this.isReadOnly,
    required this.tournamentId,
    this.width = 260.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minWidth: 260),
      child: MatchCardDetail(
        match: match,
        isReferee: isReferee,
        isReadOnly: isReadOnly,
        tournamentId: tournamentId,
      ),
    );
  }
}
