import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  const r = PlanRect(4, 4, 6, 4); // right 10, bottom 8

  test('stretching from a side keeps the opposite side', () {
    expect(resizePlan(r, PlanHandle.right, 2, 0), const PlanRect(4, 4, 8, 4));
    expect(resizePlan(r, PlanHandle.left, -2, 0), const PlanRect(2, 4, 8, 4));
    expect(resizePlan(r, PlanHandle.top, 0, 1), const PlanRect(4, 5, 6, 3));
    expect(resizePlan(r, PlanHandle.bottom, 0, -1), const PlanRect(4, 4, 6, 3));
    // Side handles ignore the other direction.
    expect(resizePlan(r, PlanHandle.right, 2, 5), const PlanRect(4, 4, 8, 4));
  });

  test('corners stretch both ways', () {
    expect(resizePlan(r, PlanHandle.bottomRight, 1, 2), const PlanRect(4, 4, 7, 6));
    expect(resizePlan(r, PlanHandle.topLeft, -1, -1), const PlanRect(3, 3, 7, 5));
    expect(resizePlan(r, PlanHandle.topRight, 1, 1), const PlanRect(4, 5, 7, 3));
    expect(resizePlan(r, PlanHandle.bottomLeft, 1, 1), const PlanRect(5, 4, 5, 5));
  });

  test('never below the minimum, past 0, or out of the room', () {
    expect(resizePlan(r, PlanHandle.left, 50, 0), const PlanRect(8, 4, 2, 4));
    expect(resizePlan(r, PlanHandle.topLeft, -50, -50), const PlanRect(0, 0, 10, 8));
    expect(resizePlan(r, PlanHandle.right, 50, 0, cols: 12), const PlanRect(4, 4, 8, 4));
    expect(resizePlan(const PlanRect(0, 0, 3, 1), PlanHandle.bottom, 0, -5, min: 1), const PlanRect(0, 0, 3, 1));
  });

  test('moving stays on the grid and inside the room', () {
    expect(movePlan(r, -10, 2), const PlanRect(0, 6, 6, 4));
    expect(movePlan(r, 50, 50, cols: 12, rows: 10), const PlanRect(6, 6, 6, 4));
    expect(movePlan(r, 3, 0), const PlanRect(7, 4, 6, 4));
  });
}
