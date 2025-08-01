interface playVisualizationParameters {
  chartType: string;
}

export function adjustVisualization(
  targettedParameters: any
){
  return targettedParameters;
}

export function playVisualization(
  params: playVisualizationParameters
){
  switch (params.chartType) {
    case "stackedBarChart":
      return playStackBarChart();
    case "pieChart":
      return playPieChart();
    case "lineChart":
      return playLineChart();
  }
  return playStackBarChart(); 
}


export function playStackBarChart(){
    return {
  "$schema": "https://vega.github.io/schema/vega-lite/v6.json",
  "description": "Grouped stacked bar chart showing hit/miss ratio per player per year, with percentage labels.",
  "background": "#f9f6ef",
  "data": {
    "url": "https://raw.githubusercontent.com/HarryLuUMN/vis-llm-game/refs/heads/harry-react-dev/public/data/baseball_str%20(1).csv",
    "format": {"type": "csv"}
  },
  "transform": [
    {
      "aggregate": [{"op": "count", "as": "count"}],
      "groupby": ["player", "year", "is_hit"]
    },
    {
      "impute": "count",
      "key": "is_hit",
      "groupby": ["player", "year"],
      "value": 0
    },
    {
      "window": [{"op": "sum", "field": "count", "as": "total_attempts"}],
      "groupby": ["player", "year"]
    },
    {"calculate": "datum.count / datum.total_attempts", "as": "percentage"},
    {"calculate": "format(datum.percentage, '.0%')", "as": "percentage_label"},
    {"calculate": "format(1 - datum.count / datum.total_attempts, '.0%')", "as": "hitting_rate_label"}
  ],
  "facet": {
    "row": {
      "field": "player",
      "type": "nominal",
      "title": "Player",
      "header": {"labelAngle": 0}
    }
  },
  "spec": {
    "width": 300,
    "layer": [
      {
        "mark": "bar",
        "encoding": {
          "x": {
            "field": "year",
            "type": "ordinal",
            "title": "Year",
            "sort": "ascending",
            "scale": {"paddingInner": 0.2},
            "axis": {"labelAngle": 0}
          },
          "y": {
            "field": "count",
            "type": "quantitative",
            "title": "Number of Attempts"
          },
          "color": {
            "field": "is_hit",
            "type": "nominal",
            "scale": {
              "domain": ["Hit", "Miss"],
              "range": ["#4CE0D2", "#22AAA1"]
            },
            "legend": {"title": "Hit Status"}
          },
          "order": {
            "field": "is_hit",
            "type": "nominal",
            "sort": ["Miss", "Hit"]
          },
          "tooltip": [
            {"field": "player", "type": "nominal", "title": "Player"},
            {"field": "year", "type": "ordinal", "title": "Year"},
            {"field": "is_hit", "type": "nominal", "title": "Hit or Miss"},
            {
              "field": "count",
              "type": "quantitative",
              "title": "Number of Attempts"
            },
            {
              "field": "percentage_label",
              "type": "nominal",
              "title": "Proportion"
            }
          ]
        }
      },
      {
        "transform": [
          {"filter": "lower(datum.is_hit) === 'miss'  && datum.percentage > 0 && datum.percentage < 1"}
        ],
        "mark": {"type": "text", "dy": -10, "color": "black", "fontSize": 11},
        "encoding": {
          "x": {"field": "year", "type": "ordinal", "sort": "ascending"},
          "y": {
              "aggregate": "sum",
              "field": "count",
              "type": "quantitative",
              "stack": "zero"
            },
            "order": {
              "field": "is_hit",
              "type": "nominal",
              "sort": ["Miss", "Hit"]
            },
          "detail": {"field": "is_hit", "type": "nominal"},
          "text": {"field": "hitting_rate_label", "type": "nominal"}
        }
      }
    ]
  },
  "config": {
    "view": {"stroke": "transparent"},
    "axis": {"labelFontSize": 12, "titleFontSize": 14},
    "legend": {"labelFontSize": 12, "titleFontSize": 14}
  }
}
}

export function playPieChart(){
  return ;
}

export function playLineChart(){
  return ;
}


