import 'package:flutter/material.dart';
import '../../../models/draft.dart';

/// The draft grid displays all picks in a round-by-team matrix.
/// Rows represent rounds, columns represent teams in draft order.
class DraftGrid extends StatelessWidget {
  final Draft draft;
  final List<DraftPick> picks;
  final String currentTeamId;
  final Function(DraftPick) onCellTap;
  final Function(SkippedPick)? onSkippedCellTap;
  final Function(SkippedPick)? onCatchUpPick;

  const DraftGrid({
    super.key,
    required this.draft,
    required this.picks,
    required this.currentTeamId,
    required this.onCellTap,
    this.onSkippedCellTap,
    this.onCatchUpPick,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with team names
              _buildHeaderRow(),
              // Grid rows for each round
              ...List.generate(
                draft.totalRounds,
                (roundIndex) => _buildRoundRow(roundIndex + 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        // Round column header
        Container(
          width: 50,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.green[800],
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
          ),
          child: const Text(
            'Rd',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        // Team headers
        ...List.generate(draft.teamCount, (index) {
          final teamId = draft.draftOrder.length > index
              ? draft.draftOrder[index]
              : 'Team ${index + 1}';
          final isMyTeam = teamId == currentTeamId;

          return Container(
            width: 80,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isMyTeam ? Colors.green[600] : Colors.green[700],
              borderRadius: index == draft.teamCount - 1
                  ? const BorderRadius.only(topRight: Radius.circular(8))
                  : null,
            ),
            child: Text(
              'T${index + 1}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                fontSize: isMyTeam ? 14 : 12,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRoundRow(int round) {
    final bool isSerpentine = draft.format == 'serpentine';
    final bool isReversedRound = isSerpentine && round % 2 == 0;

    return Row(
      children: [
        // Round number
        Container(
          width: 50,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: round == draft.currentRound
                ? Colors.green[100]
                : Colors.grey[200],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Text(
            '$round',
            style: TextStyle(
              fontWeight: round == draft.currentRound
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: round == draft.currentRound
                  ? Colors.green[800]
                  : Colors.grey[700],
            ),
          ),
        ),
        // Cells for each team
        ...List.generate(draft.teamCount, (pickIndex) {
          final int pickInRound = isReversedRound
              ? draft.teamCount - pickIndex
              : pickIndex + 1;

          final int overallPick =
              (round - 1) * draft.teamCount + (isReversedRound ? draft.teamCount - pickIndex : pickIndex + 1);

          // Get team for this cell
          final teamId = draft.draftOrder.length > pickIndex
              ? draft.draftOrder[isReversedRound ? draft.teamCount - 1 - pickIndex : pickIndex]
              : '';

          // Find pick for this cell
          final pick = picks.cast<DraftPick?>().firstWhere(
            (p) => p!.round == round && p.pickInRound == pickInRound,
            orElse: () => null,
          );

          final cellState = _getCellState(round, pickInRound, overallPick, teamId, pick);
          final isMyTeam = teamId == currentTeamId;

          return _DraftCell(
            round: round,
            pickInRound: pickInRound,
            overallPick: overallPick,
            pick: pick,
            state: cellState,
            isMyTeam: isMyTeam,
            onTap: pick != null ? () => onCellTap(pick) : null,
          );
        }),
      ],
    );
  }

  _CellState _getCellState(int round, int pickInRound, int overallPick, String teamId, DraftPick? pick) {
    if (pick != null) {
      // Check if it was a catch-up pick
      if (pick.wasCatchUp) {
        return _CellState.catchUp;
      }
      // Check if pick was traded
      if (pick.isTraded) {
        return _CellState.traded;
      }
      return _CellState.selected;
    }

    if (round == draft.currentRound && pickInRound == draft.currentPick) {
      return _CellState.onClock;
    }

    // Check if this pick was skipped
    final skippedPick = _getSkippedPick(round, pickInRound, teamId);
    if (skippedPick != null) {
      if (skippedPick.isAvailable) {
        return _CellState.catchUp;
      }
      return _CellState.skipped;
    }

    if (overallPick < draft.currentOverallPick) {
      // This should have been picked but wasn't - likely skipped
      return _CellState.skipped;
    }

    if (overallPick == draft.currentOverallPick + 1 ||
        overallPick == draft.currentOverallPick + 2) {
      return _CellState.queued;
    }

    return _CellState.empty;
  }

  SkippedPick? _getSkippedPick(int round, int pickInRound, String teamId) {
    try {
      return draft.skipQueue.firstWhere(
        (s) => s.round == round && s.pickInRound == pickInRound && s.teamId == teamId,
      );
    } catch (_) {
      return null;
    }
  }
}

enum _CellState {
  empty,
  onClock,
  queued,
  selected,
  skipped,
  catchUp,
  traded,
}

class _DraftCell extends StatelessWidget {
  final int round;
  final int pickInRound;
  final int overallPick;
  final DraftPick? pick;
  final _CellState state;
  final bool isMyTeam;
  final VoidCallback? onTap;

  const _DraftCell({
    required this.round,
    required this.pickInRound,
    required this.overallPick,
    required this.pick,
    required this.state,
    required this.isMyTeam,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 70,
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border.all(
            color: _borderColor,
            width: state == _CellState.onClock ? 2 : 1,
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Color get _backgroundColor {
    if (isMyTeam) {
      switch (state) {
        case _CellState.onClock:
          return Colors.green[100]!;
        case _CellState.selected:
          return Colors.green[50]!;
        default:
          return Colors.green[50]!.withValues(alpha: 0.5);
      }
    }

    switch (state) {
      case _CellState.empty:
        return Colors.white;
      case _CellState.onClock:
        return Colors.amber[50]!;
      case _CellState.queued:
        return Colors.grey[100]!;
      case _CellState.selected:
        return Colors.white;
      case _CellState.skipped:
        return Colors.red[50]!;
      case _CellState.catchUp:
        return Colors.orange[50]!;
      case _CellState.traded:
        return Colors.purple[50]!;
    }
  }

  Color get _borderColor {
    switch (state) {
      case _CellState.onClock:
        return Colors.amber[700]!;
      case _CellState.skipped:
        return Colors.red[300]!;
      case _CellState.catchUp:
        return Colors.orange[300]!;
      case _CellState.traded:
        return Colors.purple[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  Widget _buildContent() {
    if (pick != null) {
      return _buildSelectedContent();
    }

    switch (state) {
      case _CellState.onClock:
        return _buildOnClockContent();
      case _CellState.skipped:
        return _buildSkippedContent();
      case _CellState.catchUp:
        return _buildCatchUpContent();
      case _CellState.traded:
        return _buildTradedContent();
      case _CellState.queued:
        return _buildQueuedContent();
      default:
        return _buildEmptyContent();
    }
  }

  Widget _buildSelectedContent() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            pick!.playerName.split(' ').last,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getPositionColor(pick!.position),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              pick!.position,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pick!.mlbTeam,
            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOnClockContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time, color: Colors.amber[700], size: 20),
        const SizedBox(height: 4),
        Text(
          'ON CLOCK',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.amber[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSkippedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.skip_next, color: Colors.red[400], size: 20),
        const SizedBox(height: 4),
        Text(
          'SKIPPED',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.red[400],
          ),
        ),
      ],
    );
  }

  Widget _buildCatchUpContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.replay, color: Colors.orange[600], size: 20),
        const SizedBox(height: 4),
        Text(
          'CATCH UP',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.orange[600],
          ),
        ),
        if (isMyTeam)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange[600],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'TAP',
              style: TextStyle(
                fontSize: 7,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTradedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.swap_horiz, color: Colors.purple[400], size: 20),
        const SizedBox(height: 4),
        Text(
          'TRADED',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.purple[400],
          ),
        ),
      ],
    );
  }

  Widget _buildQueuedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$overallPick',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
        Text(
          'Next',
          style: TextStyle(fontSize: 9, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Text(
        '$overallPick',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'SP':
      case 'RP':
      case 'P':
        return Colors.blue[600]!;
      case 'C':
        return Colors.purple[600]!;
      case '1B':
      case '2B':
      case '3B':
      case 'SS':
        return Colors.brown[600]!;
      case 'OF':
      case 'LF':
      case 'CF':
      case 'RF':
        return Colors.green[600]!;
      case 'DH':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
