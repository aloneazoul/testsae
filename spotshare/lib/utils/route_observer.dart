import 'package:flutter/widgets.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

// Notifier global pour indiquer si la page Feed/Home est visible.
// Les widgets média (PostCard, ReelItem...) peuvent s'y abonner
// pour mettre en pause la lecture quand la page n'est pas visible.
final ValueNotifier<bool> feedPageVisible = ValueNotifier<bool>(true);
