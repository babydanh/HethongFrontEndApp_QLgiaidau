import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One selectable value of a [SearchFilterGroup].
typedef SearchFilterOption = ({String value, String label});

/// A filter shown as one chip with a pop-up menu (e.g. "Sân", "Trạng thái").
/// At most one option per group is active; "no option" means the group is off.
class SearchFilterGroup {
  const SearchFilterGroup({
    required this.id,
    required this.label,
    required this.options,
  });

  final String id;
  final String label;
  final List<SearchFilterOption> options;
}

/// Search text, filters and open flag of one list tab.
@immutable
class SearchFilterState {
  const SearchFilterState({
    this.open = false,
    this.query = '',
    this.selected = const {},
  });

  final bool open;
  final String query;

  /// group id -> chosen option value; absent key = group off.
  final Map<String, String> selected;

  /// Active filters plus one when there is search text: the toggle badge.
  int get activeCount => selected.length + (query.trim().isEmpty ? 0 : 1);

  bool get isActive => activeCount > 0;

  SearchFilterState copyWith({
    bool? open,
    String? query,
    Map<String, String>? selected,
  }) => SearchFilterState(
    open: open ?? this.open,
    query: query ?? this.query,
    selected: selected ?? this.selected,
  );

  /// This state without filters whose group or option is no longer offered
  /// (the list of courts or divisions changed). A stale value must neither
  /// filter invisibly nor count in the badge.
  SearchFilterState pruned(List<SearchFilterGroup> groups) {
    final valid = <String, String>{};
    for (final entry in selected.entries) {
      final group = groups.where((item) => item.id == entry.key).firstOrNull;
      final offered =
          group?.options.any((option) => option.value == entry.value) ?? false;
      if (offered) valid[entry.key] = entry.value;
    }
    return valid.length == selected.length ? this : copyWith(selected: valid);
  }
}

/// How long a tab's search state outlives its widgets: enough to survive tab
/// switches and list reloads, then it is freed with the screen.
const _keepAliveGrace = Duration(minutes: 10);

class SearchFilterNotifier extends Notifier<SearchFilterState> {
  // The family argument is the tab key; state is separate per key.
  SearchFilterNotifier(this.tabKey);

  final String tabKey;

  @override
  SearchFilterState build() {
    final link = ref.keepAlive();
    Timer? timer;
    ref.onCancel(() => timer = Timer(_keepAliveGrace, link.close));
    ref.onResume(() => timer?.cancel());
    ref.onDispose(() => timer?.cancel());
    return const SearchFilterState();
  }

  void toggleOpen() => state = state.copyWith(open: !state.open);

  void setOpen(bool open) => state = state.copyWith(open: open);

  void setQuery(String query) => state = state.copyWith(query: query);

  void setFilter(String groupId, String? value) {
    final next = {...state.selected};
    if (value == null || value.isEmpty) {
      next.remove(groupId);
    } else {
      next[groupId] = value;
    }
    state = state.copyWith(selected: next);
  }

  /// Drops filters that [groups] no longer offer.
  void prune(List<SearchFilterGroup> groups) {
    final next = state.pruned(groups);
    if (!identical(next, state)) state = next;
  }

  /// Resets text and filters; the bar stays open.
  void clear() => state = SearchFilterState(open: state.open);
}

/// Per-tab search state. Hosts build the key from the tab plus its owner, e.g.
/// `'$tournamentId:schedule'`, so each tab keeps its own text and filters.
final searchFilterProvider = NotifierProvider.autoDispose
    .family<SearchFilterNotifier, SearchFilterState, String>(
      SearchFilterNotifier.new,
    );

const _accentGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<String, String> _accentMap = {
  for (final entry in _accentGroups.entries)
    for (final rune in entry.value.runes) String.fromCharCode(rune): entry.key,
};

/// Combining diacritical marks (U+0300 to U+036F) left by decomposed input.
final RegExp _combiningMarks = RegExp(r'[̀-ͯ]');

/// Lower-cases and strips Vietnamese diacritics so "nguyen" finds "Nguyễn".
String foldSearchText(String value) {
  final lower = value.trim().toLowerCase().replaceAll(_combiningMarks, '');
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    out.write(_accentMap[char] ?? char);
  }
  return out.toString();
}

/// True when [foldedNeedle] (already passed through [foldSearchText] by the
/// caller, once per search) is empty or appears in any of [haystacks].
bool searchTextMatches(String foldedNeedle, Iterable<String> haystacks) {
  if (foldedNeedle.isEmpty) return true;
  return haystacks.any((text) => foldSearchText(text).contains(foldedNeedle));
}

/// Search icon for the toolbar: highlighted while the bar is open, with a
/// badge counting active conditions so a collapsed bar still shows them.
class SearchFilterToggle extends ConsumerWidget {
  const SearchFilterToggle({super.key, required this.tabKey});

  final String tabKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchFilterProvider(tabKey));
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final count = state.activeCount;
    return IconButton(
      key: const ValueKey('search-filter-toggle'),
      // The tooltip is the screen-reader label, so it also carries the count
      // that the visual badge shows.
      tooltip: count > 0
          ? '${l10n.searchFilterTooltip}, ${l10n.searchFilterActiveCount(count)}'
          : l10n.searchFilterTooltip,
      isSelected: state.open,
      onPressed: ref.read(searchFilterProvider(tabKey).notifier).toggleOpen,
      style: IconButton.styleFrom(
        backgroundColor: state.open
            ? AppTheme.primary.withValues(alpha: 0.14)
            : null,
      ),
      icon: ExcludeSemantics(
        child: Badge(
          key: const ValueKey('search-filter-badge'),
          isLabelVisible: count > 0,
          label: Text('$count'),
          backgroundColor: AppTheme.primary,
          textColor: Colors.white,
          child: Icon(
            Icons.search_rounded,
            color: state.open ? AppTheme.primary : colors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Drop-down panel under the toolbar: search box, filter chips and a
/// "N kết quả · Xoá lọc" line. Each tab supplies only the hint, its filter
/// groups and the number of rows that currently match.
class SearchFilterBar extends ConsumerStatefulWidget {
  const SearchFilterBar({
    super.key,
    required this.tabKey,
    required this.hint,
    required this.groups,
    required this.resultCount,
    this.hiddenCount = 0,
  });

  final String tabKey;
  final String hint;
  final List<SearchFilterGroup> groups;
  final int resultCount;

  /// Matches that exist but are not on screen now (another day, a hidden
  /// court): shown on a second line so "0 kết quả" is not misleading.
  final int hiddenCount;

  @override
  ConsumerState<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends ConsumerState<SearchFilterBar> {
  static const _debounce = Duration(milliseconds: 200);

  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  Timer? _timer;

  /// Last query this widget wrote; a different state value came from outside
  /// (clear all) and must be mirrored into the text field.
  late String _pushed;

  SearchFilterNotifier get _notifier =>
      ref.read(searchFilterProvider(widget.tabKey).notifier);

  @override
  void initState() {
    super.initState();
    _pushed = ref.read(searchFilterProvider(widget.tabKey)).query;
    _controller = TextEditingController(text: _pushed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      _pushed = text;
      _notifier.setQuery(text);
    });
  }

  /// First tap clears the text; with nothing to clear it closes the bar.
  void _onCloseTap() {
    _timer?.cancel();
    if (_controller.text.isEmpty) {
      _notifier.setOpen(false);
      return;
    }
    _controller.clear();
    _pushed = '';
    _notifier.setQuery('');
  }

  void _onClearAll() {
    _timer?.cancel();
    _controller.clear();
    _pushed = '';
    _notifier.clear();
  }

  @override
  Widget build(BuildContext context) {
    final raw = ref.watch(searchFilterProvider(widget.tabKey));
    final state = raw.pruned(widget.groups);
    if (!identical(state, raw)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifier.prune(widget.groups);
      });
    }
    ref.listen(searchFilterProvider(widget.tabKey), (prev, next) {
      // Focus (and the keyboard) only when the user just opened the bar, not
      // when the widget is rebuilt or the screen is re-entered already open.
      if (next.open && !(prev?.open ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      }
      if (next.query == _pushed) return;
      _timer?.cancel();
      _pushed = next.query;
      _controller.text = next.query;
    });
    // A bar kept mounted under another tab or route must not swallow Back.
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      // Back closes a visible bar before it pops the route.
      canPop: !(state.open && visible),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && visible) _notifier.setOpen(false);
      },
      child: AnimatedSize(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: state.open
            ? _panel(context, state)
            : const SizedBox(width: double.infinity, height: 0),
      ),
    );
  }

  Widget _panel(BuildContext context, SearchFilterState state) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final small = (textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: colors.textSecondary,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('search-filter-input'),
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(
                  key: const ValueKey('search-filter-close'),
                  tooltip: l10n.searchFilterClearText,
                  onPressed: _onCloseTap,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (widget.groups.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final group in widget.groups)
                    _GroupChip(
                      group: group,
                      value: state.selected[group.id],
                      onSelected: (value) =>
                          _notifier.setFilter(group.id, value),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.searchFilterResultCount(widget.resultCount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: small,
                      ),
                      if (widget.hiddenCount > 0)
                        Text(
                          l10n.searchFilterElsewhere(widget.hiddenCount),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: small,
                        ),
                    ],
                  ),
                ),
                if (state.isActive)
                  TextButton(
                    key: const ValueKey('search-filter-clear-all'),
                    onPressed: _onClearAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 40),
                    ),
                    child: Text(
                      l10n.searchFilterClearAll,
                      style: (textTheme.labelMedium ?? const TextStyle())
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.group,
    required this.value,
    required this.onSelected,
  });

  final SearchFilterGroup group;
  final String? value;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final selected = group.options
        .where((option) => option.value == value)
        .firstOrNull;
    final on = selected != null;
    final fg = on ? Colors.white : colors.textPrimary;
    final text = selected?.label ?? group.label;
    final style = (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
        .copyWith(fontWeight: FontWeight.w700, color: fg);
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: on ? '${group.label}: $text' : group.label,
        child: PopupMenuButton<String>(
          key: ValueKey('search-filter-group-${group.id}'),
          tooltip: group.label,
          onSelected: (picked) => onSelected(picked.isEmpty ? null : picked),
          itemBuilder: (context) => [
            PopupMenuItem(value: '', child: Text(l10n.filterAll)),
            for (final option in group.options)
              PopupMenuItem(
                key: ValueKey('search-filter-option-${option.value}'),
                value: option.value,
                child: Text(option.label),
              ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppTheme.primary : null,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: on ? AppTheme.primary : colors.border,
                ),
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: fg,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
