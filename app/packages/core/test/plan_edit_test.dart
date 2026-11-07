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

  test('a double-tapped square gets a room around it, off the others', () {
    var n = 0;
    final ctx = Ctx(newId: () => 'r${n++}', now: () => DateTime(2026, 11, 7));
    final a = addSpace(const HomeData(), ctx, 'A');
    final d = setRoomPlan(a.data, a.value.id, const PlanRect(0, 0, 6, 6));
    // Open floor: 6 x 6 centred on the tap.
    expect(planSpotAt(d, 12, 12), const PlanRect(10, 10, 6, 6));
    // Next to room A: it starts right of the wall.
    final beside = planSpotAt(d, 6, 2)!;
    expect(beside.x, 6);
    expect(beside.overlaps(const PlanRect(0, 0, 6, 6)), isFalse);
    // Inside a room: nothing.
    expect(planSpotAt(d, 2, 2), isNull);
    // A gap of one square between two rooms: too small.
    final b = addSpace(d, ctx, 'B');
    final two = setRoomPlan(b.data, b.value.id, const PlanRect(7, 0, 6, 6));
    expect(planSpotAt(two, 6, 2), isNull);
  });

  test("the plan's box is where its rooms are, not from square (0, 0)", () {
    var n = 0;
    final ctx = Ctx(newId: () => 'r${n++}', now: () => DateTime(2026, 11, 7));
    final a = addSpace(const HomeData(), ctx, 'A');
    final b = addSpace(a.data, ctx, 'B');
    var d = setRoomPlan(b.data, a.value.id, const PlanRect(4, 6, 5, 5));
    d = setRoomPlan(d, b.value.id, const PlanRect(9, 8, 3, 4));
    expect(planBounds(d), const PlanRect(4, 6, 8, 6));
    expect(planBounds(const HomeData()), isNull);
  });
}
