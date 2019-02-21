import 'render.dart';

String stringifyMap(Map map) {
  var str = "{";
  if (map == null || map.isEmpty) {
    return "{}";
  }
  map.forEach((key, value) {
    if (key == 'on') {
      return;
    }
    if (value.runtimeType == "Function") {
      return;
    }
    if (value.runtimeType == "Map") {
      str += "\"$key\": ${stringifyMap(value)},";
      return;
    }
    if (value is Component) {
      str += "\"$key\": ${stingifyComponent(value)},";
      return;
    }
    str += "\"$key\": \"$value\",";
  });
  str = str.substring(0, str.length -1);
  str += "}";
  return str;
}

String stringifyList(List list) {
  var str = "[";
  if (list == null || list.isEmpty) {
    return "[]";
  }
  list.forEach((value) {
    if (value.runtimeType == "Function") {
      return;
    }
    if (value.runtimeType == "Map") {
      str += "${value},";
      return;
    }
    if (value is Component) {
      str += "${stingifyComponent(value)},";
      return;
    }
    str += "\"$value\",";
  });
  str = str.substring(0, str.length -1);
  str += "]";
  return str;
}

String stingifyComponent(Component c){
  String childrenString = stringifyList(c.context.childrens);
  return "{\"id\": ${c.node.id},\"props\": ${stringifyMap(c.context.props)},\"tagName\": \"${c.context.tagName ?? '' }\",\"childrens\": ${childrenString}}";
}
