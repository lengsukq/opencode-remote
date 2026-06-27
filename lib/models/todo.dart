class Todo {
  final String id;
  final String task;
  final String status;

  Todo({required this.id, required this.task, this.status = 'pending'});

  bool get done => status == 'completed' || status == 'resolved';

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'] as String? ?? '',
    task: json['content'] as String? ?? json['task'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
  );
}
