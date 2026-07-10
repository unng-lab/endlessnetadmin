import 'dart:convert';

import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';
import '../../theme.dart';

class AccessControlsScreen extends StatefulWidget {
  const AccessControlsScreen({
    super.key,
    required this.policy,
    required this.canMutate,
    required this.onValidate,
    required this.onPreview,
    required this.onRunTests,
    required this.onSave,
  });

  final PolicyFileModel? policy;
  final bool canMutate;
  final Future<Map<String, dynamic>> Function(Map<String, Object?> values)
  onValidate;
  final Future<Map<String, dynamic>> Function(Map<String, Object?> values)
  onPreview;
  final Future<Map<String, dynamic>> Function() onRunTests;
  final Future<void> Function(Map<String, Object?> values) onSave;

  @override
  State<AccessControlsScreen> createState() => _AccessControlsScreenState();
}

class _AccessControlsScreenState extends State<AccessControlsScreen> {
  late final TextEditingController _editor;
  String _format = 'json';
  String _result = '';
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _editor = TextEditingController(text: _policyText(widget.policy));
    _format = widget.policy?.format.isNotEmpty == true
        ? widget.policy!.format
        : 'json';
  }

  @override
  void didUpdateWidget(covariant AccessControlsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.policy?.hash != widget.policy?.hash &&
        _editor.text.trim() == _policyText(oldWidget.policy).trim()) {
      _editor.text = _policyText(widget.policy);
    }
    if (widget.policy?.format.isNotEmpty == true) {
      _format = widget.policy!.format;
    }
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.policy;
    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 36),
      children: [
        SectionHeader(
          icon: Icons.policy_rounded,
          title: 'Доступ',
          subtitle:
              'JSON-политика, ресурсы, проверка, предпросмотр, тесты, группы, теги, IP-наборы и правила состояния устройств.',
          actions: [
            OutlinedButton.icon(
              onPressed: _working ? null : _runTests,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Запустить тесты'),
            ),
            OutlinedButton.icon(
              onPressed: _working ? null : _preview,
              icon: const Icon(Icons.difference_rounded),
              label: const Text('Предпросмотр diff'),
            ),
            OutlinedButton.icon(
              onPressed: _working ? null : _validate,
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text('Проверить'),
            ),
            if (widget.canMutate)
              FilledButton.icon(
                onPressed: _working ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Сохранить'),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const _PolicyTabs(),
        const SizedBox(height: 18),
        _PolicyEditorPanel(
          current: current,
          editor: _editor,
          format: _format,
          canMutate: widget.canMutate,
          working: _working,
          result: _result,
          onFormatChanged: (value) => setState(() => _format = value ?? 'json'),
        ),
      ],
    );
  }

  Map<String, Object?> _body() => {'text': _editor.text, 'format': _format};

  Future<void> _validate() async {
    await _run(() => widget.onValidate(_body()));
  }

  Future<void> _preview() async {
    await _run(() => widget.onPreview(_body()));
  }

  Future<void> _runTests() async {
    await _run(widget.onRunTests);
  }

  Future<void> _save() async {
    setState(() {
      _working = true;
      _result = '';
    });
    try {
      await widget.onSave(_body());
      if (!mounted) {
        return;
      }
      setState(() => _result = 'Сохранено и записано в аудит.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _result = error.toString());
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    setState(() {
      _working = true;
      _result = '';
    });
    try {
      final result = await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _result = const JsonEncoder.withIndent('  ').convert(result);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _result = error.toString());
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }
}

class _PolicyTabs extends StatelessWidget {
  const _PolicyTabs();

  static const _tabs = [
    _PolicyTabData(Icons.policy_rounded, 'Общие правила доступа'),
    _PolicyTabData(Icons.terminal_rounded, 'SSH / удаленная оболочка'),
    _PolicyTabData(Icons.verified_user_rounded, 'Автоодобрение'),
    _PolicyTabData(Icons.groups_rounded, 'Группы'),
    _PolicyTabData(Icons.sell_rounded, 'Теги'),
    _PolicyTabData(Icons.public_rounded, 'IP-наборы'),
    _PolicyTabData(Icons.dns_rounded, 'Хосты'),
    _PolicyTabData(Icons.monitor_heart_rounded, 'Состояние устройств'),
    _PolicyTabData(Icons.receipt_long_rounded, 'Атрибуты узлов'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: .72),
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            for (var index = 0; index < _tabs.length; index++) ...[
              _PolicyTab(tab: _tabs[index], active: index == 0),
              if (index != _tabs.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _PolicyTabData {
  const _PolicyTabData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _PolicyTab extends StatelessWidget {
  const _PolicyTab({required this.tab, required this.active});

  final _PolicyTabData tab;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: active ? colors.blue.withValues(alpha: .16) : Colors.transparent,
        border: Border.all(
          color: active
              ? colors.blue.withValues(alpha: .35)
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(tab.icon, size: 18, color: active ? colors.blue : colors.muted),
          const SizedBox(width: 9),
          Text(
            tab.label,
            style: TextStyle(
              color: active ? colors.blue : colors.muted,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyEditorPanel extends StatelessWidget {
  const _PolicyEditorPanel({
    required this.current,
    required this.editor,
    required this.format,
    required this.canMutate,
    required this.working,
    required this.result,
    required this.onFormatChanged,
  });

  final PolicyFileModel? current;
  final TextEditingController editor;
  final String format;
  final bool canMutate;
  final bool working;
  final String result;
  final ValueChanged<String?> onFormatChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return SurfacePanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.blue.withValues(alpha: .12),
                    border: Border.all(
                      color: colors.blue.withValues(alpha: .28),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.description_rounded, color: colors.blue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Файл политики',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JSON-политика',
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: format,
                    items: const [
                      DropdownMenuItem(value: 'json', child: Text('JSON')),
                    ],
                    onChanged: canMutate ? onFormatChanged : null,
                    decoration: const InputDecoration(labelText: 'Формат'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: _PolicyCodeEditor(editor: editor, canMutate: canMutate),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 26),
            child: _PolicyFooter(current: current, format: format),
          ),
          if (working) const LinearProgressIndicator(minHeight: 2),
          if (result.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  border: Border.all(color: colors.line),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: SelectableText(
                  result,
                  style: TextStyle(
                    color: colors.text,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PolicyCodeEditor extends StatelessWidget {
  const _PolicyCodeEditor({required this.editor, required this.canMutate});

  final TextEditingController editor;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: editor,
      builder: (context, value, child) {
        final lineCount = _visibleLineCount(value.text);
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            border: Border.all(color: colors.line.withValues(alpha: .72)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: colors.line.withValues(alpha: .7)),
                  ),
                ),
                child: Column(
                  children: [
                    for (var line = 1; line <= lineCount; line++)
                      SizedBox(
                        height: 24,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Text(
                              '$line',
                              style: TextStyle(
                                color: colors.muted.withValues(alpha: .72),
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: editor,
                  enabled: canMutate,
                  minLines: 16,
                  maxLines: null,
                  cursorColor: colors.blue,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    isDense: false,
                    contentPadding: EdgeInsets.fromLTRB(18, 14, 18, 14),
                  ),
                  style: TextStyle(
                    color: colors.text,
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.72,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PolicyFooter extends StatelessWidget {
  const _PolicyFooter({required this.current, required this.format});

  final PolicyFileModel? current;
  final String format;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final hash = current?.hash ?? '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: .72),
        border: Border.all(color: colors.line.withValues(alpha: .72)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Tooltip(
            message: hash,
            child: Text(
              'Хеш ${shortText(hash, 28)}',
              style: TextStyle(color: colors.muted),
            ),
          ),
          _FooterSeparator(color: colors.line),
          Text(
            'Версия ${current?.version ?? 0}',
            style: TextStyle(color: colors.muted),
          ),
          _FooterSeparator(color: colors.line),
          Text(
            'Формат ${current?.format ?? format}',
            style: TextStyle(color: colors.muted),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.blue.withValues(alpha: .24),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'Синтаксис корректен',
                style: TextStyle(
                  color: colors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterSeparator extends StatelessWidget {
  const _FooterSeparator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 24, color: color);
  }
}

int _visibleLineCount(String text) {
  final count = '\n'.allMatches(text).length + 1;
  return count < 16 ? 16 : count;
}

String _policyText(PolicyFileModel? policy) {
  if (policy != null && policy.text.isNotEmpty) {
    return policy.text;
  }
  return '{\n  "acls": [],\n  "groups": {},\n  "tests": []\n}';
}
