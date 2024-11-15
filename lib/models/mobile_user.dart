class MobilUser {
  String name;
  String rol;
  int collaboratorId;
  int iD;
  MobilUser(
      {required this.name,
      required this.rol,
      required this.collaboratorId,
      required this.iD});

  @override
  toString() {
    return "name: $name, rol: $rol, collaborator_id: $collaboratorId, id: $iD";
  }
}
