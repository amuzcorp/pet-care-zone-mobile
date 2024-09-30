enum SecurityType {
  NONE("NONE"),
  PSK("PSK"),
  PSK2("PSK2"),
  SAE("SAE"),
  WEP("WEP"),
  EAP("EAP"),
  PSK3("PSK3");

  final String value;

  const SecurityType(this.value);
}
