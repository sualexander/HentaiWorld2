shader_type canvas_item;

uniform vec4 modulate = vec4(0, 0, 0, 1);
uniform vec2 speed = vec2(1, 1);
uniform float rotationSpeed = 0;
uniform float checkerSize = 70.0;
uniform vec2 center = vec2(0, 0);
uniform vec4 color1 = vec4(1, 1, 1, 1);
uniform vec4 color2 = vec4(0, 0, 0, 1);
void fragment() {
	float angle = radians(TIME * rotationSpeed);
	vec2 relPos = FRAGCOORD.xy - center;
	vec2 rotatedPos;
	rotatedPos.x = cos(angle) * relPos.x - sin(angle) * relPos.y;
	rotatedPos.y = sin(angle) * relPos.x + cos(angle) * relPos.y;
	vec2 pos = rotatedPos + center + vec2(TIME * speed.x * checkerSize, TIME * speed.y * checkerSize);
	
	bool isEvenSquare = (int(floor(pos.x / checkerSize) + floor(pos.y / checkerSize)) % 2) == 0;
	COLOR = isEvenSquare ? color1 : color2;
	COLOR *= modulate;
}