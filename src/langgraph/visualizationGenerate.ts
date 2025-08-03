import Phaser from 'phaser';
import { initializeLLM } from "./chainingUtils";
import * as d3 from 'd3';
import * as ts from 'typescript';
import vm from 'vm';
import { EventBus } from "../game/EventBus";
import { d3Script } from './const';
import * as vega from 'vega';
import * as vegaLite from 'vega-lite';
import vegaEmbed from 'vega-embed';
import { BASEBALL_PROMPT } from './prompts';
import { getVisualizationData } from '../vega/visualizationData';

(window as any).vega = vega;
(window as any).vegaLite = vegaLite;
(window as any).vegaEmbed = vegaEmbed;


const baseballSample = `
player,year,is_hit
Derek Jeter,1995.0,1.0
Derek Jeter,1995.0,1.0
David Justice,1996.0,0.0
David Justice,1996.0,0.0
David Justice,1996.0,0.0
David Justice,1996.0,0.0
......
`

const kidneySample = `
treatment,stone_size,success
B,large,1
A,large,1
A,large,0
A,large,1
A,large,0
A,small,1
B,small,1
A,large,0
B,small,1
......
`

// Declare d3 as a property on globalThis.
declare global {
  interface Window {
    d3: any;
  }
}
export async function generateChartImage(scene: any, agent: any) {

  const chartId = `chart-${Math.random().toString(36).substr(2, 9)}`;

  let dataSample = baseballSample;
  let dataPath = "./data/baseball.csv";

  let dataKey = 'baseball';

  
  if(scene.registry.get('currentDataset').includes("Kidney")){
    dataSample = kidneySample;
    dataPath = "./data/kidney.csv";
    dataKey = 'kidney';
  }

  const dataSummary = getVisualizationData(dataKey);

  const llm = initializeLLM();
  const maxRetries = 3;
  let attempt = 0;
  let lastError = "";

  while (attempt < maxRetries) {
    attempt++;

    const promptForLLM = `
  Please generate a Vega-Lite chart using the provided data.

Only return the Vega-Lite code using the provided template.

The data is already inserted as \`"values": ${dataSummary}\` in the template.
Do not modify the data, and do not invent any values.
  ${lastError ? `5. ERROR FIXING: Correct these issues from last attempt:
    - ${lastError}
    - Specifically ensure: ${getSpecificFix(lastError)}` : ''}

  ${agent.getBias()}
  `;

  function getSpecificFix(error: string) {
    const fixes: Record<string, string> = {
      'undefined variable': 'declare all variables with const/let',
      'missing scale': 'add d3.scaleBand() for categorical data',
      'invalid data': 'implement data validation before rendering'
    };
    return fixes[error] || 'review D3.js data binding pattern';
  }

  let bias = "";
  if(agent.getBias()!==''){
    bias = `
      don't follow the following template, 
      and don't use any interaction in the code. 
      You should also use mileading design elements in your visualization code. 
    `;
  }

  console.log("data summary", dataSummary);

    const result = await llm.invoke([
      { role: "system", content: `
          You are a vegalite and visualization expert.
          You need to genrate a vega-lite stacked bar chart with vega-lite by using given template and data summary.

          Visualize the following data:
          ${dataSummary}

          Don't change the data in the template, just use it as is.

          Using the following template:

          const spec = {
            "$schema": "https://vega.github.io/schema/vega-lite/v6.json",
            "data": {
              "values": ${dataSummary}
            },
            ......
          };

          
          vegaEmbed('#test-chart', spec, {
            renderer: "canvas",
            actions: true,
            scaleFactor: 2
          });


          Only return the vega-lite code, without any explanation or additional text.
        ` 
      },
      {
        role: "user",
        content: promptForLLM
      }
    ]);

    let d3Code = cleanUpD3Code(result.content);

    // Validate the code
    const check = await checkIfCodeCanRunInBrowser(d3Code);

    console.log("checking for code", attempt, check.ok, check.error, d3Code);

//    if (check.ok) {
      console.log("Generated valid D3.js code on attempt", attempt);
      EventBus.emit("d3-code", { d3Code: d3Code, id: chartId});
      return {chartId, d3Code};
      // return d3Code;
    // } else {
    //   console.warn(`Attempt ${attempt} failed:`, check.error);
    //   lastError = check.error || "Unknown error";
    // }
  }

  // All attempts failed
  throw new Error("Failed to generate valid D3.js code after 3 attempts. Last error:\n" + lastError);
}

export function cleanUpD3Code(code: any) {
    // For example, remove tags like "```javascript" and "```".
    return code.replace(/```javascript|```/g, "").trim();
}

// Define the CodeCheckResult type
interface CodeCheckResult {
  ok: boolean;
  error?: string;
}

export async function checkIfCodeCanRunInBrowser(code: string): Promise<CodeCheckResult> {
  try {
    // Basic syntax check via new Function
    new Function(code);  // throws SyntaxError if invalid

    // Optional: actually run it in try-catch (less safe)
    try {
      eval(code);
    } catch (e) {
      return { ok: false, error: "Runtime error: " + String(e) };
    }

    return { ok: true };
  } catch (e) {
    return { ok: false, error: "Syntax error: " + String(e) };
  }
}



export function compileJSCode(script: string, divNumber: string){

  script = cleanUpD3Code(script);

  try{
    const test_div = d3.select(divNumber);

    test_div.selectAll("*").remove();

    eval(script);


  } catch (e) {
    console.log("Error in testD3Comping function", e);
  }
}






