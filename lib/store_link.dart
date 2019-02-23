part of 'store.dart';

typedef Component MapTo<S extends Store>(S s);

class Connect extends Component {
  MapTo<Store> _build;
  Component v;
  Connect({ @required MapTo<Store> build}) {
    _build = build;
    store.subscribe((_){
      this.setState((_){});
    });
  }
  Component build() {
    return _build(store);
  }
}