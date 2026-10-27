import 'package:flutter/material.dart';

/// Registered once on MaterialApp's navigatorObservers in main.dart.
/// Any page that wants to know "I just became visible again because
/// something on top of me was popped" subscribes to this in initState
/// (routeObserver.subscribe(this, ModalRoute.of(context)!)) and
/// implements RouteAware's didPopNext().
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();