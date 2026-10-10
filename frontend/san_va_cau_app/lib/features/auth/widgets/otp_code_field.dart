import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.enabled = true,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final bool enabled;
  final bool autofocus;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _handleChanged(String value) {
    if (value.length == 6) widget.onCompleted(value);
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      textField: true,
      label: 'Mã OTP gồm 6 chữ số',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _focusNode.requestFocus : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: List.generate(6, (index) {
                final value = index < code.length ? code[index] : '';
                final active = widget.enabled && index == code.length;
                final filled = value.isNotEmpty;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('$index-$value'),
                        tween: Tween(
                          begin: filled && !reduceMotion ? 0.82 : 1,
                          end: 1,
                        ),
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: filled
                                ? AppColors.primarySoft
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: active || filled
                                  ? AppColors.primary
                                  : AppColors.borderMuted,
                              width: active ? 1.8 : 1.2,
                            ),
                            boxShadow: active
                                ? const [
                                    BoxShadow(
                                      color: Color(0x1FDC2626),
                                      blurRadius: 10,
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: _handleChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
