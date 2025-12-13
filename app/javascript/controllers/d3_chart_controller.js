import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

// D3 Chart Controller - Renders various chart types for admin dashboards
// Usage: data-controller="d3-chart" data-d3-chart-type-value="line" data-d3-chart-data-value='[...]'
export default class extends Controller {
  static values = {
    type: { type: String, default: "line" },
    data: Array,
    colors: { type: Array, default: ["#22c55e", "#3b82f6", "#f59e0b", "#ef4444", "#8b5cf6"] },
    height: { type: Number, default: 300 },
    showLegend: { type: Boolean, default: true },
    showTooltip: { type: Boolean, default: true },
    xLabel: String,
    yLabel: String
  }

  connect() {
    this.render()
    this.resizeObserver = new ResizeObserver(() => this.render())
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
  }

  dataValueChanged() {
    this.render()
  }

  render() {
    this.element.innerHTML = ""

    if (!this.dataValue || this.dataValue.length === 0) {
      this.renderEmpty()
      return
    }

    switch (this.typeValue) {
      case "line":
        this.renderLineChart()
        break
      case "bar":
        this.renderBarChart()
        break
      case "pie":
      case "donut":
        this.renderPieChart()
        break
      case "area":
        this.renderAreaChart()
        break
      case "heatmap":
        this.renderHeatmap()
        break
      case "funnel":
        this.renderFunnel()
        break
      default:
        this.renderLineChart()
    }
  }

  renderEmpty() {
    const container = d3.select(this.element)
    container.append("div")
      .attr("class", "chart-empty")
      .style("height", `${this.heightValue}px`)
      .style("display", "flex")
      .style("align-items", "center")
      .style("justify-content", "center")
      .style("color", "var(--reasy-gray-400)")
      .text("No data available")
  }

  getMargins() {
    return { top: 20, right: 30, bottom: 40, left: 50 }
  }

  getDimensions() {
    const margin = this.getMargins()
    const width = this.element.clientWidth - margin.left - margin.right
    const height = this.heightValue - margin.top - margin.bottom
    return { width, height, margin }
  }

  createSvg() {
    const { width, height, margin } = this.getDimensions()

    return d3.select(this.element)
      .append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", `translate(${margin.left},${margin.top})`)
  }

  renderLineChart() {
    const { width, height } = this.getDimensions()
    const svg = this.createSvg()
    const data = this.dataValue

    // Parse dates if string
    const parseDate = d3.timeParse("%Y-%m-%d")
    const formattedData = data.map(d => ({
      ...d,
      date: typeof d.date === "string" ? parseDate(d.date) : d.date,
      value: +d.value
    }))

    // Scales
    const x = d3.scaleTime()
      .domain(d3.extent(formattedData, d => d.date))
      .range([0, width])

    const y = d3.scaleLinear()
      .domain([0, d3.max(formattedData, d => d.value) * 1.1])
      .range([height, 0])

    // Line
    const line = d3.line()
      .x(d => x(d.date))
      .y(d => y(d.value))
      .curve(d3.curveMonotoneX)

    // Area fill
    const area = d3.area()
      .x(d => x(d.date))
      .y0(height)
      .y1(d => y(d.value))
      .curve(d3.curveMonotoneX)

    // Draw area
    svg.append("path")
      .datum(formattedData)
      .attr("fill", this.colorsValue[0])
      .attr("fill-opacity", 0.1)
      .attr("d", area)

    // Draw line
    svg.append("path")
      .datum(formattedData)
      .attr("fill", "none")
      .attr("stroke", this.colorsValue[0])
      .attr("stroke-width", 2)
      .attr("d", line)

    // Dots
    svg.selectAll(".dot")
      .data(formattedData)
      .enter()
      .append("circle")
      .attr("class", "dot")
      .attr("cx", d => x(d.date))
      .attr("cy", d => y(d.value))
      .attr("r", 4)
      .attr("fill", this.colorsValue[0])
      .style("cursor", "pointer")

    // Axes
    svg.append("g")
      .attr("transform", `translate(0,${height})`)
      .call(d3.axisBottom(x).ticks(6).tickFormat(d3.timeFormat("%b %d")))
      .selectAll("text")
      .style("fill", "var(--reasy-gray-500)")

    svg.append("g")
      .call(d3.axisLeft(y).ticks(5).tickFormat(d => this.formatNumber(d)))
      .selectAll("text")
      .style("fill", "var(--reasy-gray-500)")

    // Tooltip
    if (this.showTooltipValue) {
      this.addTooltip(svg, formattedData, x, y, "date", "value")
    }
  }

  renderBarChart() {
    const { width, height } = this.getDimensions()
    const svg = this.createSvg()
    const data = this.dataValue

    // Scales
    const x = d3.scaleBand()
      .domain(data.map(d => d.label))
      .range([0, width])
      .padding(0.3)

    const y = d3.scaleLinear()
      .domain([0, d3.max(data, d => +d.value) * 1.1])
      .range([height, 0])

    // Bars
    svg.selectAll(".bar")
      .data(data)
      .enter()
      .append("rect")
      .attr("class", "bar")
      .attr("x", d => x(d.label))
      .attr("y", d => y(d.value))
      .attr("width", x.bandwidth())
      .attr("height", d => height - y(d.value))
      .attr("fill", (d, i) => d.color || this.colorsValue[i % this.colorsValue.length])
      .attr("rx", 4)
      .style("cursor", "pointer")

    // Value labels on bars
    svg.selectAll(".bar-label")
      .data(data)
      .enter()
      .append("text")
      .attr("class", "bar-label")
      .attr("x", d => x(d.label) + x.bandwidth() / 2)
      .attr("y", d => y(d.value) - 5)
      .attr("text-anchor", "middle")
      .style("fill", "var(--reasy-gray-600)")
      .style("font-size", "12px")
      .text(d => this.formatNumber(d.value))

    // Axes
    svg.append("g")
      .attr("transform", `translate(0,${height})`)
      .call(d3.axisBottom(x))
      .selectAll("text")
      .style("fill", "var(--reasy-gray-500)")
      .style("font-size", "11px")
      .attr("transform", "rotate(-30)")
      .attr("text-anchor", "end")

    svg.append("g")
      .call(d3.axisLeft(y).ticks(5).tickFormat(d => this.formatNumber(d)))
      .selectAll("text")
      .style("fill", "var(--reasy-gray-500)")
  }

  renderPieChart() {
    const { width, height } = this.getDimensions()
    const data = this.dataValue
    const radius = Math.min(width, height) / 2
    const innerRadius = this.typeValue === "donut" ? radius * 0.6 : 0

    const svg = d3.select(this.element)
      .append("svg")
      .attr("width", width + 100)
      .attr("height", height + 40)
      .append("g")
      .attr("transform", `translate(${width / 2},${height / 2 + 20})`)

    const pie = d3.pie()
      .value(d => d.value)
      .sort(null)

    const arc = d3.arc()
      .innerRadius(innerRadius)
      .outerRadius(radius)

    const arcs = svg.selectAll(".arc")
      .data(pie(data))
      .enter()
      .append("g")
      .attr("class", "arc")

    arcs.append("path")
      .attr("d", arc)
      .attr("fill", (d, i) => d.data.color || this.colorsValue[i % this.colorsValue.length])
      .style("cursor", "pointer")
      .on("mouseover", function() {
        d3.select(this).attr("opacity", 0.8)
      })
      .on("mouseout", function() {
        d3.select(this).attr("opacity", 1)
      })

    // Labels
    const labelArc = d3.arc()
      .innerRadius(radius * 0.7)
      .outerRadius(radius * 0.7)

    arcs.append("text")
      .attr("transform", d => `translate(${labelArc.centroid(d)})`)
      .attr("text-anchor", "middle")
      .style("fill", "white")
      .style("font-size", "12px")
      .style("font-weight", "500")
      .text(d => d.data.value > 0 ? `${Math.round(d.data.value / d3.sum(data, x => x.value) * 100)}%` : "")

    // Legend
    if (this.showLegendValue) {
      const legend = svg.append("g")
        .attr("transform", `translate(${radius + 20}, ${-radius})`)

      data.forEach((d, i) => {
        const legendRow = legend.append("g")
          .attr("transform", `translate(0, ${i * 24})`)

        legendRow.append("rect")
          .attr("width", 12)
          .attr("height", 12)
          .attr("rx", 2)
          .attr("fill", d.color || this.colorsValue[i % this.colorsValue.length])

        legendRow.append("text")
          .attr("x", 18)
          .attr("y", 10)
          .style("fill", "var(--reasy-gray-600)")
          .style("font-size", "12px")
          .text(`${d.label} (${this.formatNumber(d.value)})`)
      })
    }
  }

  renderAreaChart() {
    const { width, height } = this.getDimensions()
    const svg = this.createSvg()
    const data = this.dataValue

    // Parse dates
    const parseDate = d3.timeParse("%Y-%m-%d")
    const formattedData = data.map(d => ({
      ...d,
      date: typeof d.date === "string" ? parseDate(d.date) : d.date,
      value: +d.value
    }))

    // Scales
    const x = d3.scaleTime()
      .domain(d3.extent(formattedData, d => d.date))
      .range([0, width])

    const y = d3.scaleLinear()
      .domain([0, d3.max(formattedData, d => d.value) * 1.1])
      .range([height, 0])

    // Gradient
    const gradient = svg.append("defs")
      .append("linearGradient")
      .attr("id", "area-gradient")
      .attr("x1", "0%").attr("y1", "0%")
      .attr("x2", "0%").attr("y2", "100%")

    gradient.append("stop")
      .attr("offset", "0%")
      .attr("stop-color", this.colorsValue[0])
      .attr("stop-opacity", 0.4)

    gradient.append("stop")
      .attr("offset", "100%")
      .attr("stop-color", this.colorsValue[0])
      .attr("stop-opacity", 0.05)

    // Area
    const area = d3.area()
      .x(d => x(d.date))
      .y0(height)
      .y1(d => y(d.value))
      .curve(d3.curveMonotoneX)

    svg.append("path")
      .datum(formattedData)
      .attr("fill", "url(#area-gradient)")
      .attr("d", area)

    // Line
    const line = d3.line()
      .x(d => x(d.date))
      .y(d => y(d.value))
      .curve(d3.curveMonotoneX)

    svg.append("path")
      .datum(formattedData)
      .attr("fill", "none")
      .attr("stroke", this.colorsValue[0])
      .attr("stroke-width", 2)
      .attr("d", line)

    // Axes
    svg.append("g")
      .attr("transform", `translate(0,${height})`)
      .call(d3.axisBottom(x).ticks(6).tickFormat(d3.timeFormat("%b %d")))
      .selectAll("text")
      .style("fill", "var(--reasy-gray-500)")

    svg.append("g")
      .call(d3.axisLeft(y).ticks(5).tickFormat(d => this.formatNumber(d)))
      .selectAll("text")
      .style("fill", "var(--reasy-gray-500)")
  }

  renderHeatmap() {
    const { width, height, margin } = this.getDimensions()
    const data = this.dataValue

    // Get unique x and y values
    const xValues = [...new Set(data.map(d => d.x))]
    const yValues = [...new Set(data.map(d => d.y))]

    const cellWidth = width / xValues.length
    const cellHeight = height / yValues.length

    const svg = this.createSvg()

    // Color scale
    const maxValue = d3.max(data, d => d.value)
    const colorScale = d3.scaleSequential()
      .domain([0, maxValue])
      .interpolator(d3.interpolateGreens)

    // Cells
    svg.selectAll(".cell")
      .data(data)
      .enter()
      .append("rect")
      .attr("class", "cell")
      .attr("x", d => xValues.indexOf(d.x) * cellWidth)
      .attr("y", d => yValues.indexOf(d.y) * cellHeight)
      .attr("width", cellWidth - 2)
      .attr("height", cellHeight - 2)
      .attr("fill", d => colorScale(d.value))
      .attr("rx", 2)

    // X axis labels
    svg.selectAll(".x-label")
      .data(xValues)
      .enter()
      .append("text")
      .attr("x", (d, i) => i * cellWidth + cellWidth / 2)
      .attr("y", height + 15)
      .attr("text-anchor", "middle")
      .style("fill", "var(--reasy-gray-500)")
      .style("font-size", "10px")
      .text(d => d)

    // Y axis labels
    svg.selectAll(".y-label")
      .data(yValues)
      .enter()
      .append("text")
      .attr("x", -10)
      .attr("y", (d, i) => i * cellHeight + cellHeight / 2)
      .attr("text-anchor", "end")
      .attr("dominant-baseline", "middle")
      .style("fill", "var(--reasy-gray-500)")
      .style("font-size", "10px")
      .text(d => d)
  }

  renderFunnel() {
    const { width, height } = this.getDimensions()
    const data = this.dataValue
    const svg = this.createSvg()

    const maxValue = d3.max(data, d => d.value)
    const barHeight = height / data.length - 10

    data.forEach((d, i) => {
      const barWidth = (d.value / maxValue) * width
      const x = (width - barWidth) / 2

      svg.append("rect")
        .attr("x", x)
        .attr("y", i * (barHeight + 10))
        .attr("width", barWidth)
        .attr("height", barHeight)
        .attr("fill", d.color || this.colorsValue[i % this.colorsValue.length])
        .attr("rx", 4)

      // Label
      svg.append("text")
        .attr("x", width / 2)
        .attr("y", i * (barHeight + 10) + barHeight / 2)
        .attr("text-anchor", "middle")
        .attr("dominant-baseline", "middle")
        .style("fill", "white")
        .style("font-size", "12px")
        .style("font-weight", "500")
        .text(`${d.label}: ${this.formatNumber(d.value)}`)
    })
  }

  addTooltip(svg, data, x, y, xKey, yKey) {
    const tooltip = d3.select(this.element)
      .append("div")
      .attr("class", "chart-tooltip")
      .style("position", "absolute")
      .style("visibility", "hidden")
      .style("background", "var(--reasy-gray-900)")
      .style("color", "white")
      .style("padding", "8px 12px")
      .style("border-radius", "6px")
      .style("font-size", "12px")
      .style("pointer-events", "none")
      .style("z-index", "100")

    const focus = svg.append("g")
      .style("display", "none")

    focus.append("circle")
      .attr("r", 6)
      .attr("fill", this.colorsValue[0])
      .attr("stroke", "white")
      .attr("stroke-width", 2)

    const bisect = d3.bisector(d => d[xKey]).left

    svg.append("rect")
      .attr("width", this.getDimensions().width)
      .attr("height", this.getDimensions().height)
      .style("fill", "none")
      .style("pointer-events", "all")
      .on("mouseover", () => {
        focus.style("display", null)
        tooltip.style("visibility", "visible")
      })
      .on("mouseout", () => {
        focus.style("display", "none")
        tooltip.style("visibility", "hidden")
      })
      .on("mousemove", (event) => {
        const x0 = x.invert(d3.pointer(event)[0])
        const i = bisect(data, x0, 1)
        const d0 = data[i - 1]
        const d1 = data[i] || d0
        const d = x0 - d0[xKey] > d1[xKey] - x0 ? d1 : d0

        focus.attr("transform", `translate(${x(d[xKey])},${y(d[yKey])})`)

        const formatDate = d3.timeFormat("%b %d, %Y")
        tooltip
          .style("left", `${x(d[xKey]) + 60}px`)
          .style("top", `${y(d[yKey])}px`)
          .html(`<strong>${formatDate(d[xKey])}</strong><br/>${this.formatNumber(d[yKey])}`)
      })
  }

  formatNumber(n) {
    if (n >= 1000000) {
      return `$${(n / 1000000).toFixed(1)}M`
    } else if (n >= 1000) {
      return `$${(n / 1000).toFixed(1)}K`
    }
    return n.toLocaleString()
  }
}
