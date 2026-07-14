import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Ponto único de acesso ao banco SQLite local.
/// A arquitetura permite, futuramente, trocar essa camada por uma
/// implementação com sincronização em nuvem sem afetar o domínio,
/// pois os repositórios dependem apenas das interfaces em `domain/repositories`.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'moto_gestor.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receitas (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        km_rodados REAL NOT NULL,
        valor_recebido REAL NOT NULL,
        valor_por_km REAL NOT NULL,
        observacao TEXT,
        criado_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE despesas (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        categoria TEXT NOT NULL,
        valor REAL NOT NULL,
        observacao TEXT,
        criado_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categorias_despesa (
        nome TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE configuracoes (
        chave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');

    // Categorias padrão sugeridas (o usuário pode adicionar outras livremente)
    const categoriasPadrao = [
      'Gasolina', 'Óleo', 'Filtro de óleo', 'Pneu', 'Câmara de ar',
      'Manutenção', 'Lavagem', 'Freios', 'Relação', 'Capacete',
      'Equipamentos', 'Alimentação', 'Estacionamento', 'Outras despesas',
    ];
    for (final categoria in categoriasPadrao) {
      await db.insert('categorias_despesa', {'nome': categoria});
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
