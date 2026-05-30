import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleSignInWebButton() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.clamp(220.0, 360.0);
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: width,
          height: 44,
          child: google_web.renderButton(
            configuration: google_web.GSIButtonConfiguration(
              type: google_web.GSIButtonType.standard,
              theme: google_web.GSIButtonTheme.outline,
              size: google_web.GSIButtonSize.large,
              text: google_web.GSIButtonText.continueWith,
              shape: google_web.GSIButtonShape.pill,
              logoAlignment: google_web.GSIButtonLogoAlignment.left,
              minimumWidth: width,
              locale: 'ko',
            ),
          ),
        ),
      );
    },
  );
}
