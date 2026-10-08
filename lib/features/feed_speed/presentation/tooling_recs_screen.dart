import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/net/edge_functions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ai_answer.dart';
import '../domain/cut_parameters.dart';
import '../domain/material_spec.dart';

class ToolingRecsScreen extends ConsumerStatefulWidget {
  final MaterialSpec material;
  final OperationType operation;
  final double        diameter;
  final int           flutes;
  final UnitSystem    units;

  const ToolingRecsScreen({
    super.key,
    required this.material,
    required this.operation,
    required this.diameter,
    required this.flutes,
    required this.units,
  });

  @override
  ConsumerState<ToolingRecsScreen> createState() => _ToolingRecsScreenState();
}

class _ToolingRecsScreenState extends ConsumerState<ToolingRecsScreen> {
  String? _answer;
  bool    _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ref.read(edgeInvokerProvider)(
        'tooling-recs',
        body: {
          'material':      widget.material.name,
          'operation':     widget.operation == OperationType.roughing ? 'roughing' : 'finishing',
          'diameter':      widget.diameter,
          'units':         widget.units == UnitSystem.metric ? 'metric' : 'imperial',
          'toolMaterial':  'carbide',
          'flutes':        widget.flutes,
          'language':      ref.read(localeProvider),
          'format':        'markdown',
          'clientTimeout': kAiTimeout.inSeconds,
        },
        timeout: kAiTimeout,
      );
      if (!mounted) return;
      final answer = data['answer'];
      setState(() {
        _loading = false;
        if (answer is String && answer.trim().isNotEmpty) {
          _answer = answer;
        } else {
          _error = ref.read(appStringsProvider).errAiBusy;
        }
      });
    } on EdgeFunctionError catch (e) {
      if (!mounted) return;
      if (e.kind == EdgeErrorKind.proRequired) {
        // The calculator only opens this screen for Pro users, so this means
        // the subscription lapsed. Swap this screen for the paywall.
        final router = GoRouter.of(context);
        Navigator.pop(context);
        router.push(RouteNames.subscription);
        return;
      }
      setState(() { _error = e.message(ref.read(appStringsProvider)); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.toolingTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(s.toolingLoading,
                  style: const TextStyle(color: AppColors.textSecondary)),
              ])
            : _error != null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, color: AppColors.errorRed, size: 40),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load,
                      child: Text(s.commonRetry)),
                  ])
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:        AppColors.primaryDim,
                            borderRadius: BorderRadius.circular(8),
                            border:       Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.build_circle, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              '${widget.material.name} · '
                              '${widget.diameter}${widget.units == UnitSystem.metric ? "mm" : "in"} · '
                              '${widget.flutes}fl',
                              style: const TextStyle(fontSize: 12, color: AppColors.primary),
                            )),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        AiAnswer(
                          _answer ?? '',
                          onCodeCopied: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.progLibCopied), duration: const Duration(seconds: 1)),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
