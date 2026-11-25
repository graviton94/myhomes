import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  const r = PlanRect(4, 4, 8, 6); // 10 px squares: 40..120 × 40..100
  PlanHandle? grab(double x, double y, {double scale = 1}) => planGrab(r, x, y, cell: 10, scale: scale)?.handle;

  test('the picked block is grabbed near its walls; corners stretch both ways', () {
    expect(planGrab(r, 80, 70, cell: 10), same(PlanGrab.move));
    expect(grab(80, 70), isNull);
    expect(grab(30, 30), PlanHandle.topLeft); // outside the corner
    expect(grab(45, 45), PlanHandle.topLeft); // inside the corner
    expect(grab(125, 105), PlanHandle.bottomRight);
    expect(grab(0, 70), PlanHandle.left); // 40 px out
    expect(grab(130, 70), PlanHandle.right);
    expect(grab(80, 35), PlanHandle.top);
    // A small block (2 × 1 squares) still has a middle to move it by.
    expect(planGrab(const PlanRect(0, 0, 2, 1), 10, 5, cell: 10), same(PlanGrab.move));
    expect(planGrab(const PlanRect(0, 0, 2, 1), -10, 5, cell: 10)?.handle, PlanHandle.left);
    expect(planGrab(r, -20, 70, cell: 10), isNull); // too far
    // Zoomed in twice, the zone is as wide on the screen: half on the plan.
    expect(planGrab(r, 0, 70, cell: 10, scale: 2), isNull);
    expect(grab(20, 70, scale: 2), PlanHandle.left);
  });

  test('stretching and moving go on past the start of the squares', () {
    expect(stretchPlan(r, PlanHandle.topLeft, -6, -5), const PlanRect(-2, -1, 14, 11));
    expect(stretchPlan(r, PlanHandle.right, -9, 0), const PlanRect(4, 4, 2, 6)); // not below 2
    expect(shiftPlan(r, -10, 0), const PlanRect(-6, 4, 8, 6));
    // Furniture stays on the room's floor.
    const room = PlanRect(0, 0, 10, 8);
    expect(shiftPlan(const PlanRect(2, 2, 3, 1), 20, -5, within: room), const PlanRect(7, 0, 3, 1));
    expect(stretchPlan(const PlanRect(2, 2, 3, 1), PlanHandle.bottomRight, 20, 20, min: 1, within: room), const PlanRect(2, 2, 8, 6));
  });

  test('a wall one square from a neighbour is pulled onto it, never held back', () {
    const kitchen = PlanRect(12, 4, 5, 5);
    // Moving right, one square short of the kitchen: snaps to touch it.
    final (moved, pulled) = magnetPlan(const PlanRect(3, 4, 8, 6), const PlanRect(0, 4, 8, 6), null, [kitchen]);
    expect(moved, const PlanRect(4, 4, 8, 6));
    expect(pulled, isTrue);
    // Already touching and stretched one square further: it goes over.
    final (over, again) = magnetPlan(const PlanRect(4, 4, 9, 6), r, PlanHandle.right, [kitchen]);
    expect(over, const PlanRect(4, 4, 9, 6));
    expect(again, isFalse);
  });

  test('overlaps are found; a saved plan starts at 0, 0', () {
    final plans = {'a': const PlanRect(-3, 2, 4, 4), 'b': const PlanRect(0, 0, 4, 4), 'c': const PlanRect(10, 10, 2, 2)};
    expect(overlappingPlans(plans), {'a', 'b'});
    expect(normalizePlans(plans), {'a': const PlanRect(0, 2, 4, 4), 'b': const PlanRect(3, 0, 4, 4), 'c': const PlanRect(13, 10, 2, 2)});
  });

  test('saving the house draft places rooms and takes the rest off', () {
    var n = 0;
    final ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 11, 25));
    var d = const HomeData();
    final a = addSpace(d, ctx, 'A');
    final b = addSpace(a.data, ctx, 'B');
    d = setRoomPlan(b.data, b.value.id, const PlanRect(0, 0, 4, 4));
    d = saveRoomPlans(d, {a.value.id: const PlanRect(-2, -2, 4, 4)});
    expect(d.space(a.value.id)!.plan, const PlanRect(0, 0, 4, 4));
    expect(d.space(b.value.id)!.plan, isNull);
  });

  test('two rooms may not share a name; outside places are apart', () {
    var n = 0;
    final ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 11, 25));
    final a = addSpace(const HomeData(), ctx, '다용도실');
    final d = addSpace(a.data, ctx, '창고', outside: true).data;
    expect(spaceNameTaken(d, '다용도실'), isTrue);
    expect(spaceNameTaken(d, ' 다용 도실 '), isTrue);
    expect(spaceNameTaken(d, '다용도실', except: a.value.id), isFalse); // its own name
    expect(spaceNameTaken(d, '창고'), isFalse); // that one is outside
    expect(spaceNameTaken(d, '창고', outside: true), isTrue);
  });

  test('new spots stand on the floor; one dragged to another room goes there with its code', () {
    var n = 0;
    final ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 11, 25));
    final living = addSpace(const HomeData(), ctx, '거실');
    final bed = addSpace(living.data, ctx, '안방');
    var d = setRoomPlan(setRoomPlan(bed.data, living.value.id, const PlanRect(0, 0, 8, 6)), bed.value.id, const PlanRect(8, 0, 6, 6));
    final tv = addContainer(d, ctx, spaceId: living.value.id, name: 'TV장');
    final shelf = addContainer(tv.data, ctx, spaceId: living.value.id, name: '선반');
    d = placeOnFloor(shelf.data, [tv.value.id, shelf.value.id]);
    expect(d.container(tv.value.id)!.plan, const PlanRect(0, 0, 2, 1));
    expect(d.container(shelf.value.id)!.plan, const PlanRect(2, 0, 2, 1)); // next to it, not on it
    d = moveToRoomFloor(d, tv.value.id, bed.value.id, const PlanRect(1, 1, 2, 1));
    final moved = d.container(tv.value.id)!;
    expect(moved.spaceId, bed.value.id);
    expect(moved.plan, const PlanRect(1, 1, 2, 1));
    expect(moved.code, startsWith(d.space(bed.value.id)!.code));
  });
}
