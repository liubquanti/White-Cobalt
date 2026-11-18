import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular progress indicator in the app's colours.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    const indicator = CircularProgressIndicator(
      year2023: false,
      color: Colors.white,
      backgroundColor: Colors.grey,
    );
    return size == null ? indicator : SizedBox.square(dimension: size, child: indicator);
  }
}

/// Full-screen centred spinner.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: AppSpinner());
}

/// Shimmering placeholder bar.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(15)),
    this.base = AppColors.outline,
  });

  final double height;
  final double? width;
  final BorderRadius borderRadius;
  final Color base;

  @override
  Widget build(BuildContext context) {
    return CardLoading(
      height: height,
      width: width,
      borderRadius: borderRadius,
      cardLoadingTheme: CardLoadingTheme(colorOne: base, colorTwo: AppColors.borderSubtle),
    );
  }
}

/// Centred error message with action buttons (Retry, Service status, …).
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({super.key, required this.message, required this.actions});

  final String message;
  final List<ErrorAction> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.gap,
              children: [
                for (final action in actions)
                  ElevatedButton(onPressed: action.onPressed, child: Text(action.label)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorAction {
  const ErrorAction(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}
