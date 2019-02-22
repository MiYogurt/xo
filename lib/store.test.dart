// import 'store.dart';

// class TodoOne extends Action {}


class AppState {
  String app_name;
  AppState(this.app_name);
  AppState copy(){
    return AppState(this.app_name);
  }

  invode(){}
}

// AppState Reducer(AppState state, Action action) {
//   if (action is TodoOne) {
//     return state.copy()..app_name = "good man";
//   }
//   return state;
// }

main(List<String> args) {
  // var store = Store();
  // store.registerModule(Reducer, initState: AppState('nice work'));
  // print(store.getState<AppState>().app_name);
  // store.dispatch(TodoOne());
  // print(store.getState<AppState>().app_name);
  dynamic app_state =AppState('123');
  print(app_state.invode());
  app_state.invode = () => print("123");
  print(app_state.invode());
}