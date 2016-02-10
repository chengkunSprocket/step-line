width  = 960
height = 500
r = 30
colors = d3.scale.category10()

mousedownNode = null
mouseupNode = null
mousedownLink = null

resetMouseAction = ->
  mousedownNode = null
  mouseupNode = null
  mousedownLink = null

svg = d3.select('body')
  .append('svg')
  .attr('oncontextmenu', 'return false;')
  .attr('width', width)
  .attr('height', height)

svg.append('svg:defs').append('svg:marker')
    .attr('id', 'end-arrow')
    .attr('viewBox', '0 -5 10 10')
    .attr('refX', 6)
    .attr('markerWidth', 3)
    .attr('markerHeight', 3)
    .attr('orient', 'auto')
  .append('svg:path')
    .attr('d', 'M0,-5L10,0L0,5')
    .attr('fill', '#000')

svg.append('svg:defs').append('svg:marker')
    .attr('id', 'start-arrow')
    .attr('viewBox', '0 -5 10 10')
    .attr('refX', 4)
    .attr('markerWidth', 3)
    .attr('markerHeight', 3)
    .attr('orient', 'auto')
  .append('svg:path')
    .attr('d', 'M10,-5L0,0L10,5')
    .attr('fill', '#000')

nodes = [
  {
    id: 'step1'
    targets: ['step2', 'step3', 'step4', 'terminator']
  }
  {
    id: 'step2'
    targets: ['step3']
  }
  {
    id: 'step3'
    targets: ['terminator']
  }
  {
    id: 'step4'
    targets: ['terminator']
  }
  {
    id: 'terminator'
    targets: []
  }
]

links = []
for node, index in nodes
  node.index = index
  for target in node.targets
    n = nodes.filter (n) ->
      return n.id is target
    links.push
      source: node
      target: n[0]
      left: false
      right: true
      direct: 1

setPos = (d) ->
  return {
    x: width * (d.index + 1) / (nodes.length + 1)
    y: height / 2
  }

setPath = (d) ->
  direct = d.direct or 1
  deltaIndex = d.target.index - d.source.index
  sx = 1
  sy = 4
  deltaX = d.target.x - d.source.x
  deltaY = d.target.y - d.source.y
  dist = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
  normX = deltaX / dist
  normY = deltaY / dist
  sourcePadding = r + 6
  targetPadding = r + 6
  sourceX = d.source.x + (sourcePadding * normX)
  sourceY = d.source.y + (sourcePadding * normY)
  targetX = d.target.x - (targetPadding * normX)
  targetY = d.target.y - (targetPadding * normY)

  if deltaIndex is 1
    return "M#{sourceX},#{sourceY}L#{targetX},#{targetY}"
  else
    sourceX -= sx * deltaIndex
    sourceY -= sy * deltaIndex
    targetX += sx * deltaIndex
    targetY -= sy * deltaIndex
    cx = (targetX + sourceX) / 2
    cy = (240 - 40 * (deltaIndex - 1)) * direct
    return "M#{sourceX},#{sourceY} C#{cx},#{cy} #{cx},#{cy} #{targetX},#{targetY}"


arrows = svg.append('svg:g').selectAll '.link'
steps = svg.append('svg:g').selectAll '.step'

reset = ->
  groups = steps.data(nodes)
          .enter().append('g')
          .attr('transform', (d) ->
            pos = setPos d
            x = pos.x
            y = pos.y
            d.x = x
            d.y = y
            "translate(#{x}, #{y})"
          )

  arrows = arrows.data(links)
  arrows.enter().append('path')
          .attr('class', 'link')
          .attr('d', (d) ->
            return setPath d
          )
          .style('marker-start', (d) ->
            status = ''
            status = 'url(#start-arrow)' if d.left
            status
          )
          .style('marker-end', (d) ->
            status = ''
            status = 'url(#end-arrow)' if d.right
            status
          )
  arrows.exit().remove()
  circles = groups.append('circle')
          .attr('class', 'step')
          .attr('stroke', (d) ->
            d3.rgb(colors(d.index)).darker().toString()
          )
          .attr('stroke-width', 2)
          .style('fill', (d) ->
            d3.rgb colors(d.index)
          )
          .attr('r', r)
          .on('mouseover', (d) ->
            d3.select(this).attr 'transform', 'scale(1.1)'
          )
          .on('mouseout', (d) ->
            d3.select(this).attr 'transform', ''
          )
          .on('mousedown', (d) ->
            mousedownNode = d
            dragLine
              .style('marker-end', 'url(#end-arrow)')
              .classed('hidden', false)
              .attr('d', "M#{mousedownNode.x},#{mousedownNode.y}L#{mousedownNode.x},#{mousedownNode.y}")
          )
          .on('mouseup', (d) ->
            if not mousedownNode
              return
            dragLine
              .classed('hidden', true)
              .style('marker-end', '')
            mouseupNode = d
            if mousedownNode is mouseupNode
              resetMouseAction()
              return
            d3.select(this).attr 'transform', ''

            source = mouseupNode
            target = mousedownNode
            direction = 'left'
            if mousedownNode.index < mouseupNode.index
              source = mousedownNode
              target = mouseupNode
              direction = 'right'

            filters = links.filter (l) ->
              return (l.source is source and l.target is target)
            link = filters[0]
            if link
              link[direction] = true
              if target.y > source.y
                link.direct = -1
              else
                link.direct = 1
            else
              link =
                source: source
                target: target
                left: false
                right: false
              link[direction] = true
              if target.y > source.y
                link.direct = -1
              else
                link.direct = 1
              links.push link
            reset()
          )

  ids = groups.append('text')
        .attr('dy', 4)
        .attr('fill', '#fff')
        .attr('text-anchor', 'middle')
        .text( (d) ->
          d.id
        )

dragLine = svg.append('svg:path')
  .attr('class', 'link dragline hidden')
  .attr('d', 'M0,0L0,0')

mousedown = ->
  svg.classed 'active', true
  point = d3.mouse this
  node =
    id

mousemove = ->
  if not mousedownNode
    return
  point = d3.mouse this
  dragLine.attr 'd', "M#{mousedownNode.x},#{mousedownNode.y}L#{point[0]},#{point[1]}"

mouseup = ->
  if not mousedownNode
    return
  dragLine
    .classed('hidden', true)
    .style('marker-end', '')
  svg.classed('active', false)
  resetMouseAction()

svg
#  .on('mousedown', mousedown)
  .on('mousemove', mousemove)
  .on('mouseup', mouseup)

reset()
