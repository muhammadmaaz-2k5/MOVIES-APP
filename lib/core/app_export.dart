// Barrel file — re-exports all shared app dependencies.
// Every file that does `import '...core/app_export.dart'` gets these for free.

export 'package:flutter/material.dart';
export 'package:go_router/go_router.dart';
export 'package:sizer/sizer.dart';

export '../theme/app_theme.dart';
export '../routes/app_routes.dart';

export '../widgets/custom_error_widget.dart';
export '../widgets/custom_icon_widget.dart';
export '../widgets/custom_image_widget.dart';
export '../widgets/status_badge_widget.dart';
export '../widgets/empty_state_widget.dart';
export '../widgets/loading_skeleton_widget.dart';
export '../widgets/app_navigation.dart';
export '../widgets/app_scaffold.dart';
export '../widgets/download_button.dart';
export 'app_config.dart';
