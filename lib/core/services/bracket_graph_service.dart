import 'package:graphview/GraphView.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

class BracketGraphService {
  static void _ensureSingleRoot(Graph graph, Map<String, Node> nodeMap) {
    // Đếm số cạnh đi vào (in-degree) của mỗi node.
    // Với cách addEdge(parent, child), in-degree của parent là 0 (nếu nó là Root).
    final inDegrees = <Node, int>{};
    for (final node in graph.nodes) {
      inDegrees[node] = 0;
    }
    for (final edge in graph.edges) {
      inDegrees[edge.destination] = (inDegrees[edge.destination] ?? 0) + 1;
    }

    final roots = inDegrees.entries.where((e) => e.value == 0).map((e) => e.key).toList();

    // Nếu có nhiều hơn 1 root, thêm một Dummy Root để nối tất cả lại, tránh crash BuchheimWalker
    if (roots.length > 1) {
      final dummyMatch = MatchModel(
        id: 'DUMMY_ROOT',
        round: 0,
        matchNumber: 0,
        bracketPosition: const BracketPosition(round: 0, position: 0),
        updatedAt: DateTime.now(),
      );
      final dummyNode = Node.Id(dummyMatch);
      graph.addNode(dummyNode);
      for (final root in roots) {
        graph.addEdge(dummyNode, root);
      }
    }
  }

  /// Xây dựng đồ thị (Graph) cho Single Elimination
  /// Đồ thị được xây dựng dưới dạng cây (Tree) từ Trận Chung kết (Root) rẽ nhánh ra các vòng trước (Leaves).
  static Graph buildSingleEliminationGraph(List<MatchModel> matches) {
    final graph = Graph()..isTree = true;
    
    // Map để lưu trữ Node tương ứng với mỗi Match ID
    final nodeMap = <String, Node>{};

    // Lọc ra các trận đấu KHÔNG phải là BYE vs BYE và KHÔNG bị hủy
    final validMatches = matches.where((m) => 
      !(m.team1Id == 'BYE' && m.team2Id == 'BYE') && m.status != 'cancelled'
    ).toList();

    // Tạo các Node
    for (final match in validMatches) {
      final node = Node.Id(match);
      nodeMap[match.id] = node;
      graph.addNode(node);
    }

    // Single Elimination: match ở vòng r có nextMatchId ở vòng r+1
    // Để BuchheimWalker vẽ Root ở cuối (bên phải), ta thiết lập cạnh từ nextMatch -> currentMatch
    for (final match in validMatches) {
      if (match.nextMatchId.isNotEmpty) {
        final parentNode = nodeMap[match.nextMatchId];
        final childNode = nodeMap[match.id];
        
        if (parentNode != null && childNode != null) {
          graph.addEdge(parentNode, childNode);
        }
      }
    }

    _ensureSingleRoot(graph, nodeMap);

    return graph;
  }

  /// Xây dựng đồ thị cho Double Elimination
  static Graph buildDoubleEliminationGraph(List<MatchModel> matches, {required String bracketType}) {
    final graph = Graph()..isTree = true;
    
    // Lọc theo loại bracket và BỎ QUA các trận bị hủy
    final filteredMatches = matches.where((m) => 
      m.bracketPosition.bracket == bracketType && m.status != 'cancelled'
    ).toList();
    final nodeMap = <String, Node>{};

    // Lọc bỏ trận BYE vs BYE
    final validFilteredMatches = filteredMatches.where((m) => !(m.team1Id == 'BYE' && m.team2Id == 'BYE')).toList();

    for (final match in validFilteredMatches) {
      final node = Node.Id(match);
      nodeMap[match.id] = node;
      graph.addNode(node);
    }

    for (final match in validFilteredMatches) {
      if (match.nextMatchId.isNotEmpty) {
        final parentNode = nodeMap[match.nextMatchId];
        final childNode = nodeMap[match.id];
        
        if (parentNode != null && childNode != null) {
          graph.addEdge(parentNode, childNode);
        }
      }
    }

    _ensureSingleRoot(graph, nodeMap);

    return graph;
  }
}
