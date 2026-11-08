extends Node3D

const COUNT := 9
const RADIUS_X := 61.0
const RADIUS_Z := 37.0
var cars: Array = []
var cam: Camera3D
var hud: Label
var info: Label
var message: Label
var mode := 1
var camera_style := 0
var finished := false
var debris: Array = []
var smoke_elapsed := 0.0

func material(col: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = col
    m.roughness = 0.82
    return m

func block(parent: Node3D, size: Vector3, pos: Vector3, col: Color, collider := false) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.position = pos
    n.material_override = material(col)
    parent.add_child(n)
    if collider:
        var body := StaticBody3D.new()
        body.position = pos
        parent.add_child(body)
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        cs.shape = shape
        body.add_child(cs)
    return n

func ring(inner_x: float, inner_z: float, outer_x: float, outer_z: float, color: Color, y: float) -> void:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(160):
        var a := TAU * float(i) / 160.0
        var b := TAU * float(i + 1) / 160.0
        var inner_a := Vector3(cos(a) * inner_x, y, sin(a) * inner_z)
        var inner_b := Vector3(cos(b) * inner_x, y, sin(b) * inner_z)
        var outer_a := Vector3(cos(a) * outer_x, y, sin(a) * outer_z)
        var outer_b := Vector3(cos(b) * outer_x, y, sin(b) * outer_z)
        for v in [inner_a, outer_a, inner_b, outer_a, outer_b, inner_b]:
            surface.add_vertex(v)
    surface.generate_normals()
    var n := MeshInstance3D.new()
    n.mesh = surface.commit()
    var m := material(color)
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    n.material_override = m
    add_child(n)

func _ready() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.47, 0.71, 0.91)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color.WHITE
    environment.ambient_light_energy = 0.9
    world.environment = environment
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, 20, 0)
    sun.light_energy = 1.5
    add_child(sun)
    block(self, Vector3(310, 0.6, 260), Vector3(0, -0.35, 0), Color(0.26, 0.47, 0.19), true)
    ring(43.0, 21.0, 79.0, 53.0, Color(0.49, 0.34, 0.21), 0.02)
    ring(43.0, 21.0, 43.8, 21.8, Color(0.89, 0.86, 0.68), 0.04)
    ring(78.0, 52.0, 79.0, 53.0, Color(0.89, 0.86, 0.68), 0.04)
    ring(60.0, 36.0, 60.25, 36.25, Color(0.68, 0.51, 0.31), 0.05)
    for i in range(96):
        var a := TAU * float(i) / 96.0
        var x := cos(a) * 82.0
        var z := sin(a) * 56.0
        var wall := block(self, Vector3(4.4, 1.1, 1.0), Vector3(x, 0.55, z), Color(0.9, 0.26, 0.12) if i % 2 == 0 else Color(0.84, 0.83, 0.77), true)
        wall.rotation.y = -atan2(56.0 * cos(a), -82.0 * sin(a))
        var body := wall.get_parent().get_child(wall.get_index() + 1) as StaticBody3D
        if body != null:
            body.rotation.y = wall.rotation.y
    for i in range(36):
        var a := TAU * float(i) / 36.0
        var x := cos(a) * 100.0
        var z := sin(a) * 76.0
        block(self, Vector3(0.9, 5, 0.9), Vector3(x, 2.5, z), Color(0.36, 0.21, 0.11))
        block(self, Vector3(5, 7, 5), Vector3(x, 7, z), Color(0.09, 0.32 + 0.06 * float(i % 3), 0.12))
    block(self, Vector3(27, 6, 12), Vector3(-110, 3, 0), Color(0.42, 0.47, 0.53))
    block(self, Vector3(29, 0.8, 14), Vector3(-110, 6.4, 0), Color(0.18, 0.22, 0.28))
    block(self, Vector3(34, 5, 12), Vector3(0, 3, -90), Color(0.24, 0.29, 0.33))
    for i in range(5):
        block(self, Vector3(32, 0.35, 1.5), Vector3(0, 5.8 + float(i) * 0.65, -94 + float(i) * 1.7), Color(0.7, 0.72, 0.72))
    for i in range(12):
        block(self, Vector3(2.1, 0.045, 2.0), Vector3(-11.0 + float(i) * 2.0, 0.08, -36.5), Color(0.97, 0.97, 0.9) if i % 2 == 0 else Color(0.09, 0.09, 0.09))
    cam = Camera3D.new()
    cam.current = true
    cam.fov = 75.0
    add_child(cam)
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := VBoxContainer.new()
    panel.position = Vector2(25, 20)
    layer.add_child(panel)
    hud = Label.new()
    hud.add_theme_font_size_override("font_size", 28)
    panel.add_child(hud)
    info = Label.new()
    info.add_theme_font_size_override("font_size", 19)
    panel.add_child(info)
    var help := Label.new()
    help.text = "WASD / Arrows: drive    Space: handbrake\n1: Race    2: Derby    C: Camera    R: Restart"
    panel.add_child(help)
    message = Label.new()
    message.add_theme_font_size_override("font_size", 23)
    panel.add_child(message)
    reset_game()

func make_car(index: int, pos: Vector3, yaw: float) -> Dictionary:
    var colors := [Color(0.92, 0.12, 0.08), Color(0.14, 0.38, 0.94), Color(0.97, 0.75, 0.1), Color(0.17, 0.72, 0.32), Color(0.86, 0.24, 0.78), Color(0.94, 0.47, 0.09), Color(0.21, 0.75, 0.75), Color(0.94, 0.89, 0.80), Color(0.56, 0.57, 0.93)]
    var car := CharacterBody3D.new()
    car.name = "Luca" if index == 0 else "Racer_%d" % index
    car.position = pos
    car.rotation.y = yaw
    car.collision_layer = 2
    car.collision_mask = 1 | 2
    car.floor_snap_length = 0.4
    add_child(car)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.15, 1.1, 4.35)
    collider.shape = shape
    car.add_child(collider)
    var paint: Color = colors[index]
    block(car, Vector3(2.18, 0.68, 4.3), Vector3(0, 0, 0), paint)
    block(car, Vector3(1.75, 0.12, 1.65), Vector3(0, 1.16, 0.15), paint.darkened(0.15))
    block(car, Vector3(1.7, 0.7, 0.14), Vector3(0, 0.78, -0.72), Color(0.08, 0.16, 0.23))
    block(car, Vector3(1.7, 0.63, 0.14), Vector3(0, 0.78, 1.05), Color(0.08, 0.16, 0.23))
    block(car, Vector3(1.95, 0.1, 1.18), Vector3(0, 0.4, -1.49), paint.lightened(0.15))
    for side in [-1.0, 1.0]:
        block(car, Vector3(0.12, 0.5, 1.3), Vector3(side * 0.86, 0.8, 0.12), Color(0.08, 0.16, 0.22))
        for z in [-1.4, 1.4]:
            block(car, Vector3(0.46, 0.96, 0.9), Vector3(side * 1.15, -0.34, z), Color(0.035, 0.035, 0.04))
            block(car, Vector3(0.07, 0.46, 0.46), Vector3(side * 1.39, -0.34, z), Color(0.61, 0.62, 0.62))
    var front := block(car, Vector3(2.35, 0.26, 0.28), Vector3(0, -0.1, -2.2), Color(0.13, 0.13, 0.13))
    var back := block(car, Vector3(2.35, 0.26, 0.28), Vector3(0, -0.1, 2.2), Color(0.13, 0.13, 0.13))
    return {"node": car, "speed": 0.0, "health": 100.0, "progress": 0.0, "last_angle": atan2(pos.z / RADIUS_Z, pos.x / RADIUS_X), "dead": false, "front": front, "rear": back, "damage_cooldown": 0.0, "ai_direction": 1.0}

func reset_game() -> void:
    for car_data in cars:
        var node: Node3D = car_data["node"]
        if is_instance_valid(node):
            remove_child(node)
            node.queue_free()
    cars.clear()
    finished = false
    message.text = "GO! 3 LAPS" if mode == 1 else "DEMOLITION DERBY!"
    for i in range(COUNT):
        var angle := -PI / 2.0 - 0.09 * float(i)
        var p := Vector3(cos(angle) * (RADIUS_X + float(i % 2) * 3.0), 1.0, sin(angle) * (RADIUS_Z + float(i % 2) * 2.5))
        if mode == 2:
            angle = TAU * float(i) / float(COUNT)
            p = Vector3(cos(angle) * 19.0, 1.0, sin(angle) * 14.0)
        var yaw := -angle if mode == 2 else -PI / 2.0
        cars.append(make_car(i, p, yaw))
    cam.global_position = Vector3(0, 12, -54)

func controls(i: int) -> Vector2:
    if i == 0:
        var throttle := Input.get_axis("ui_down", "ui_up")
        var steer := Input.get_axis("ui_left", "ui_right")
        if Input.is_key_pressed(KEY_W): throttle = 1.0
        if Input.is_key_pressed(KEY_S): throttle = -1.0
        if Input.is_key_pressed(KEY_A): steer = -1.0
        if Input.is_key_pressed(KEY_D): steer = 1.0
        return Vector2(throttle, steer)
    var car: CharacterBody3D = cars[i]["node"]
    var destination := Vector3.ZERO
    if mode == 1:
        var a := atan2(car.global_position.z / RADIUS_Z, car.global_position.x / RADIUS_X) + 0.28
        destination = Vector3(cos(a) * (RADIUS_X + float(i % 2) * 2.0), 0, sin(a) * (RADIUS_Z + float(i % 2) * 1.5))
    else:
        destination = (cars[0]["node"] as CharacterBody3D).global_position
    var direction := (destination - car.global_position).normalized()
    var forward := -car.global_transform.basis.z
    var error := forward.signed_angle_to(direction, Vector3.UP)
    return Vector2(0.45 if absf(error) > 1.0 else 1.0, clampf(-error * 2.0, -1.0, 1.0))

func damage(i: int, value: float, at: Vector3) -> void:
    if bool(cars[i]["dead"]) or float(cars[i]["damage_cooldown"]) > 0.0: return
    cars[i]["damage_cooldown"] = 0.45
    cars[i]["health"] = maxf(0.0, float(cars[i]["health"]) - value)
    cars[i]["speed"] = float(cars[i]["speed"]) * 0.7
    var car: CharacterBody3D = cars[i]["node"]
    var front_hit := car.to_local(at).z < 0.0
    var part: MeshInstance3D = cars[i]["front"] if front_hit else cars[i]["rear"]
    if is_instance_valid(part) and float(cars[i]["health"]) < 75.0:
        var rubble := RigidBody3D.new()
        rubble.mass = 2
        rubble.global_position = part.global_position
        add_child(rubble)
        var p := MeshInstance3D.new()
        p.mesh = part.mesh
        p.material_override = part.material_override
        rubble.add_child(p)
        var shape := CollisionShape3D.new()
        var b := BoxShape3D.new()
        b.size = Vector3(2.35, 0.26, 0.28)
        shape.shape = b
        rubble.add_child(shape)
        rubble.apply_central_impulse(Vector3(randf_range(-6, 6), 10, randf_range(-6, 6)))
        part.queue_free()
        if front_hit: cars[i]["front"] = null
        else: cars[i]["rear"] = null
        debris.append({"node": rubble, "time": 0.0})
    for k in range(5):
        var spark := MeshInstance3D.new()
        var ball := SphereMesh.new()
        ball.radius = 0.13
        ball.height = 0.26
        spark.mesh = ball
        spark.material_override = material(Color(1.0, 0.58, 0.08))
        spark.position = at + Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1))
        add_child(spark)
        debris.append({"node": spark, "time": 9.25})
    if float(cars[i]["health"]) <= 0.0:
        cars[i]["dead"] = true

func _physics_process(dt: float) -> void:
    for i in range(cars.size()):
        var data: Dictionary = cars[i]
        var car: CharacterBody3D = data["node"]
        data["damage_cooldown"] = maxf(0.0, float(data["damage_cooldown"]) - dt)
        var ctrl := Vector2.ZERO if bool(data["dead"]) else controls(i)
        var s := float(data["speed"])
        if ctrl.x > 0.05:
            s = move_toward(s, (37.0 if i == 0 else 28.0) * (0.3 + 0.7 * float(data["health"]) / 100.0), dt * 16.0)
        elif ctrl.x < -0.05:
            s = move_toward(s, -11.0 if s <= 0.0 else 0.0, dt * 22.0)
        else:
            s = move_toward(s, 0.0, dt * (16.0 if bool(data["dead"]) else 5.5))
        if i == 0 and Input.is_key_pressed(KEY_SPACE):
            s = move_toward(s, 0.0, dt * 24.0)
        car.rotate_y(-ctrl.y * signf(s) * clampf(absf(s) / 12.0, 0.0, 1.0) * 1.75 * dt)
        var forward := -car.global_transform.basis.z
        car.velocity.x = forward.x * s
        car.velocity.z = forward.z * s
        car.velocity.y = -0.1 if car.is_on_floor() else car.velocity.y - 22.0 * dt
        car.move_and_slide()
        data["speed"] = s
        if float(data["damage_cooldown"]) <= 0.0:
            for j in range(car.get_slide_collision_count()):
                var hit := car.get_slide_collision(j)
                var other := hit.get_collider()
                if other is CharacterBody3D and other != car and absf(s) > 5.0:
                    var other_i := -1
                    for k in range(cars.size()):
                        if cars[k]["node"] == other: other_i = k
                    if other_i >= 0:
                        damage(i, maxf(6.0, absf(s) * 0.35), hit.get_position())
                        damage(other_i, maxf(5.0, absf(s) * 0.3), hit.get_position())
                elif other is StaticBody3D and absf(s) > 12.0:
                    damage(i, maxf(5.0, absf(s) * 0.32), hit.get_position())
        if mode == 1:
            var angle := atan2(car.global_position.z / RADIUS_Z, car.global_position.x / RADIUS_X)
            var diff := wrapf(angle - float(data["last_angle"]), -PI, PI)
            if diff > 0.0 and diff < 0.5:
                data["progress"] = float(data["progress"]) + diff
            data["last_angle"] = angle
        if car.global_position.y < -8.0:
            car.global_position = Vector3(61, 1.0, -36) if mode == 1 else Vector3(0, 1, 0)
            data["speed"] = 0.0
    for i in range(debris.size() - 1, -1, -1):
        debris[i]["time"] = float(debris[i]["time"]) + dt
        if float(debris[i]["time"]) > 10.0:
            var object: Node = debris[i]["node"]
            if is_instance_valid(object): object.queue_free()
            debris.remove_at(i)

func _process(dt: float) -> void:
    if cars.is_empty(): return
    var player: CharacterBody3D = cars[0]["node"]
    var direction := -player.global_transform.basis.z
    var goal := player.global_position - direction * 12.0 + Vector3(0, 6.5, 0)
    if camera_style == 1: goal = player.global_position + Vector3(0, 25, 0.5)
    if camera_style == 2: goal = player.global_position + direction * 1.5 + Vector3(0, 2.7, 0)
    cam.global_position = cam.global_position.lerp(goal, clampf(dt * 5.0, 0.0, 1.0))
    cam.look_at(player.global_position + direction * 4.0 + Vector3(0, 0.6, 0), Vector3.UP)
    hud.text = "LUCA'S AMAZING RACE  |  %d km/h" % int(absf(float(cars[0]["speed"])) * 3.6)
    if mode == 1:
        var position := 1
        for i in range(1, cars.size()):
            if float(cars[i]["progress"]) > float(cars[0]["progress"]): position += 1
        var lap := int(float(cars[0]["progress"]) / TAU) + 1
        info.text = "DIRT OVAL  |  Position %d / %d  |  Lap %d / 3  |  Health %d%%" % [position, COUNT, mini(lap, 3), int(cars[0]["health"])]
        if lap >= 4 and not finished:
            finished = true
            message.text = "FINISHED! POSITION %d. PRESS R TO RESTART" % position
    else:
        var alive := 0
        for data in cars:
            if not bool(data["dead"]): alive += 1
        info.text = "DEMOLITION DERBY  |  Cars left: %d / %d  |  Health %d%%" % [alive, COUNT, int(cars[0]["health"])]
        if not finished and (bool(cars[0]["dead"]) or alive <= 1):
            finished = true
            message.text = "WRECKED! PRESS R TO RETRY" if bool(cars[0]["dead"]) else "DERBY CHAMPION! PRESS R"
    smoke_elapsed += dt
    if smoke_elapsed > 0.15:
        smoke_elapsed = 0.0
        for data in cars:
            if float(data["health"]) < 50.0:
                var smoke := MeshInstance3D.new()
                var mesh := SphereMesh.new()
                mesh.radius = 0.3
                mesh.height = 0.6
                smoke.mesh = mesh
                smoke.material_override = material(Color(0.24, 0.24, 0.24))
                smoke.global_position = (data["node"] as Node3D).global_position + Vector3(0, 1.6, 0)
                add_child(smoke)
                debris.append({"node": smoke, "time": 9.15})

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo: return
    if event.keycode == KEY_1:
        mode = 1
        reset_game()
    elif event.keycode == KEY_2:
        mode = 2
        reset_game()
    elif event.keycode == KEY_C:
        camera_style = (camera_style + 1) % 3
    elif event.keycode == KEY_R:
        reset_game()
