local tween = {}

function tween.linear(t, b, c, d)
  return c * t / d + b
end

function tween.easeInQuad(t, b, c, d)
  t = t / d
  return c * t * t + b
end

function tween.easeOutQuad(t, b, c, d)
  t = t / d
  return -c * t * (t - 2) + b
end

return tween
