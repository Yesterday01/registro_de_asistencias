class Collaborator {
  int id;
  int code;
  String first_name;
  String last_name;
  String last_name_m;
  String occupation;
  String branch;
  Collaborator({
    required this.id,
    required this.code,
    required this.first_name,
    required this.last_name,
    required this.last_name_m,
    required this.occupation,
    required this.branch,
  });

  @override
  toString() {
    return "name: $first_name, last_name: $last_name, "
        "last_name_m: $last_name_m, Puesto: $occupation, Branch: "
        "$branch, collaborator_id: $id, code: $code";
  }
}
