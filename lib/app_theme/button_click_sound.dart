import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class ClickableButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const ClickableButton({
    super.key,
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click); // Play the click sound
        if (onPressed != null) {
          onPressed!(); // Call the original onPressed function
        }
      },
      child: child,
    );
  }
}
