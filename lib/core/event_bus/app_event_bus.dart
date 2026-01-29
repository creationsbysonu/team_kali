import 'dart:async';

abstract class AppEvent {}

class ProductCreatedEvent extends AppEvent{
  final dynamic product;

  ProductCreatedEvent(this.product);
}

class ProductUpdatedEvent extends AppEvent {
  final dynamic product;

  ProductUpdatedEvent(this.product);
}

class ProductRemovedEvent extends AppEvent{
  final String productId;

  ProductRemovedEvent(this.productId);
}

class VariantCreatedEvent extends AppEvent {
  final dynamic variant;

  VariantCreatedEvent(this.variant);
  
}

class VariantUpdatedEvent extends AppEvent{
  final dynamic variant;

  VariantUpdatedEvent(this.variant);
}

class VariantDeletedEvent extends AppEvent {
  final String variantId;

  VariantDeletedEvent(this.variantId);
}


class AppEventBus {
  // Singleton instance
  static final AppEventBus _instance = AppEventBus._internal();
  factory AppEventBus() => _instance;
  AppEventBus._internal();

  // Stream controller with broadcast capability to allow multiple listeners
  final _eventController = StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get events => _eventController.stream;

  // Method to fire events to all listeners
  void fire(AppEvent event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}