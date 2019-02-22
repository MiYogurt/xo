import 'render.dart';
import 'ployfill.dart';
import 'package:meta/meta.dart';

part 'store_link.dart';

var store;

typedef StoreState Reducer<StoreState, Action>(StoreState state, Action action);
typedef void CallBack(String name);
abstract class Action {}
abstract class StoreState {
  StoreState copy();
}
class Store {
  Map modules = {};
  Map states = {};
  Map<String, List<CallBack>> listeners = {};
  registerModule<S extends StoreState>(Reducer<S, Action> reduce,{ S initState, String namespace = 'default' }){
    modules[namespace] = reduce;
    if (initState != null) {
      states[namespace] = initState;
    }
    return this;
  }
  S getState<S extends StoreState>({String namespace = 'default'}) {
    return states[namespace];
  }
  dispatch<A extends Action>(A action, {String namespace = 'default'}){
    if (namespace == 'default') {
      modules.forEach((namspace, reduce) {
        var oldState = states[namespace];
        states[namespace] = reduce(states[namespace], action);
        if (states[namespace] != oldState) {
          this.invokeSubscribeCallBack(namespace);
        }
      });
    } else {
      var reduce = modules[namespace];
      var oldState = states[namespace];
      states[namespace] =reduce(states[namespace], action);
      if (states[namespace] != oldState) {
        this.invokeSubscribeCallBack(namespace);
      }
    }
    return this;
  }
  
  void invokeSubscribeCallBack([String namespace]){
    if (namespace == null) {
      listeners.forEach((key, value) {
        if (value != null) {
          for (var listener in value) {
            Function.apply(listener, [namespace]);
          }
        }
      });
      return;
    }
    if (listeners[namespace] == null) {
      return;
    }
    for (var listener in listeners[namespace]) {
      if (listener != null) {
        Function.apply(listener, [namespace]);
      }
    }

  }

  subscribe(Function listener, {String namespace = 'default'}){
    if (listeners[namespace] == null) {
      listeners[namespace] = [listener];
    } else {
      listeners[namespace].add(listener);
    }
  }
}


Store createStore(){
  if (store == null) {
    store = Store();
  }
  return store;
}
