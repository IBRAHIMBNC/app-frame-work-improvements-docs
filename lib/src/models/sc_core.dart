class SCCore {
  String id;

  DateTime? createdAt;

  DateTime? updatedAt;

  int order;

  bool isCache;

  SCCore({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? order,
    bool? isCache,
  })  : id = id ?? "",
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        order = order ?? 0,
        isCache = isCache ?? false;

  Map<String, dynamic> toJson() => {
        "id": id,
        "order_value": order,
      };

  SCCore.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? "",
        createdAt = json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
        updatedAt = json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'])
            : null,
        order = json['order_value'] ?? 0,
        isCache = false;
}
