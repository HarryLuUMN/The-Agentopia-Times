export function playStackBarChart() {
    return {
        $schema: 'https://vega.github.io/schema/vega-lite/v6.json',
        description:
            'Grouped stacked bar chart showing hit/miss ratio per player per year, with percentage labels.',
        background: '#f9f6ef',
        data: {
            url: 'https://raw.githubusercontent.com/HarryLuUMN/vis-llm-game/refs/heads/harry-react-dev/public/data/baseball_str%20(1).csv',
            format: { type: 'csv' },
        },
        transform: [
            {
                aggregate: [{ op: 'count', as: 'count' }],
                groupby: ['player', 'year', 'is_hit'],
            },
            {
                impute: 'count',
                key: 'is_hit',
                groupby: ['player', 'year'],
                value: 0,
            },
            {
                window: [{ op: 'sum', field: 'count', as: 'total_attempts' }],
                groupby: ['player', 'year'],
            },
            {
                calculate: 'datum.count / datum.total_attempts',
                as: 'percentage',
            },
            {
                calculate: "format(datum.percentage, '.0%')",
                as: 'percentage_label',
            },
            {
                calculate:
                    "format(1 - datum.count / datum.total_attempts, '.0%')",
                as: 'hitting_rate_label',
            },
        ],
        facet: {
            row: {
                field: 'player',
                type: 'nominal',
                title: 'Player',
                header: { labelAngle: 0 },
            },
        },
        spec: {
            width: 300,
            layer: [
                {
                    mark: 'bar',
                    encoding: {
                        x: {
                            field: 'year',
                            type: 'ordinal',
                            title: 'Year',
                            sort: 'ascending',
                            scale: { paddingInner: 0.2 },
                            axis: { labelAngle: 0 },
                        },
                        y: {
                            field: 'count',
                            type: 'quantitative',
                            title: 'Number of Attempts',
                        },
                        color: {
                            field: 'is_hit',
                            type: 'nominal',
                            scale: {
                                domain: ['Hit', 'Miss'],
                                range: ['#4CE0D2', '#22AAA1'],
                            },
                            legend: { title: 'Hit Status' },
                        },
                        order: {
                            field: 'is_hit',
                            type: 'nominal',
                            sort: ['Miss', 'Hit'],
                        },
                        tooltip: [
                            {
                                field: 'player',
                                type: 'nominal',
                                title: 'Player',
                            },
                            { field: 'year', type: 'ordinal', title: 'Year' },
                            {
                                field: 'is_hit',
                                type: 'nominal',
                                title: 'Hit or Miss',
                            },
                            {
                                field: 'count',
                                type: 'quantitative',
                                title: 'Number of Attempts',
                            },
                            {
                                field: 'percentage_label',
                                type: 'nominal',
                                title: 'Proportion',
                            },
                        ],
                    },
                },
                {
                    transform: [
                        {
                            filter: "lower(datum.is_hit) === 'miss'  && datum.percentage > 0 && datum.percentage < 1",
                        },
                    ],
                    mark: {
                        type: 'text',
                        dy: -10,
                        color: 'black',
                        fontSize: 11,
                    },
                    encoding: {
                        x: {
                            field: 'year',
                            type: 'ordinal',
                            sort: 'ascending',
                        },
                        y: {
                            aggregate: 'sum',
                            field: 'count',
                            type: 'quantitative',
                            stack: 'zero',
                        },
                        order: {
                            field: 'is_hit',
                            type: 'nominal',
                            sort: ['Miss', 'Hit'],
                        },
                        detail: { field: 'is_hit', type: 'nominal' },
                        text: { field: 'hitting_rate_label', type: 'nominal' },
                    },
                },
            ],
        },
        config: {
            view: { stroke: 'transparent' },
            axis: { labelFontSize: 12, titleFontSize: 14 },
            legend: { labelFontSize: 12, titleFontSize: 14 },
        },
    };
}

export function playPieChart() {
    return {
        $schema: 'https://vega.github.io/schema/vega-lite/v5.json',
        description:
            'Pie charts per player with correctly calculated hitting rate.',
        data: {
            values: [
                {
                    category: 'David Justice',
                    value: 104,
                    year: 1995,
                    tag: 'hit',
                },
                { category: 'Derek Jeter', value: 12, year: 1995, tag: 'hit' },
                {
                    category: 'David Justice',
                    value: 45,
                    year: 1996,
                    tag: 'hit',
                },
                { category: 'Derek Jeter', value: 183, year: 1996, tag: 'hit' },
                {
                    category: 'David Justice',
                    value: 307,
                    year: 1995,
                    tag: 'miss',
                },
                { category: 'Derek Jeter', value: 36, year: 1995, tag: 'miss' },
                {
                    category: 'David Justice',
                    value: 95,
                    year: 1996,
                    tag: 'miss',
                },
                {
                    category: 'Derek Jeter',
                    value: 399,
                    year: 1996,
                    tag: 'miss',
                },
            ],
        },
        transform: [
            {
                aggregate: [{ op: 'sum', field: 'value', as: 'total' }],
                groupby: ['category', 'tag'],
            },
            {
                pivot: 'tag',
                value: 'total',
                groupby: ['category'],
            },
            {
                calculate: 'datum.hit / (datum.hit + datum.miss)',
                as: 'hitting_rate',
            },
            {
                fold: ['hit', 'miss'],
                as: ['tag', 'total'],
            },
            {
                calculate:
                    "'Hitting Rate: ' + format(datum.hitting_rate, '.1%')",
                as: 'hitting_rate_label',
            },
        ],
        facet: {
            column: {
                field: 'category',
                type: 'nominal',
                title: 'Player',
            },
        },
        spec: {
            width: 150,
            height: 150,
            layer: [
                {
                    mark: { type: 'arc', outerRadius: 70 },
                    encoding: {
                        theta: { field: 'total', type: 'quantitative' },
                        color: {
                            field: 'tag',
                            type: 'nominal',
                            scale: {
                                domain: ['hit', 'miss'],
                                range: ['#4CE0D2', '#FF8C94'],
                            },
                            legend: { title: 'Outcome' },
                        },
                        tooltip: [
                            { field: 'category', type: 'nominal' },
                            { field: 'tag', type: 'nominal' },
                            { field: 'total', type: 'quantitative' },
                            {
                                field: 'hitting_rate_label',
                                type: 'nominal',
                                title: 'Hit Rate',
                            },
                        ],
                    },
                },
                {
                    transform: [{ filter: "datum.tag === 'hit'" }],
                    mark: {
                        type: 'text',
                        dy: -70,
                        fontSize: 14,
                        fontWeight: 'bold',
                        color: 'black',
                    },
                    encoding: {
                        text: {
                            field: 'hitting_rate_label',
                            type: 'nominal',
                        },
                    },
                },
            ],
        },
    };
}

export function playHeatmap() {
    return {
        $schema: 'https://vega.github.io/schema/vega-lite/v5.json',
        description: 'Heatmap of hitting rate per player per year.',
        data: {
            values: [
                {
                    category: 'David Justice',
                    value: 104,
                    year: 1995,
                    tag: 'hit',
                },
                { category: 'Derek Jeter', value: 12, year: 1995, tag: 'hit' },
                {
                    category: 'David Justice',
                    value: 45,
                    year: 1996,
                    tag: 'hit',
                },
                { category: 'Derek Jeter', value: 183, year: 1996, tag: 'hit' },
                {
                    category: 'David Justice',
                    value: 307,
                    year: 1995,
                    tag: 'miss',
                },
                { category: 'Derek Jeter', value: 36, year: 1995, tag: 'miss' },
                {
                    category: 'David Justice',
                    value: 95,
                    year: 1996,
                    tag: 'miss',
                },
                {
                    category: 'Derek Jeter',
                    value: 399,
                    year: 1996,
                    tag: 'miss',
                },
            ],
        },
        transform: [
            {
                aggregate: [{ op: 'sum', field: 'value', as: 'total' }],
                groupby: ['category', 'year', 'tag'],
            },
            {
                pivot: 'tag',
                value: 'total',
                groupby: ['category', 'year'],
            },
            {
                calculate: 'datum.hit / (datum.hit + datum.miss)',
                as: 'hitting_rate',
            },
        ],
        mark: 'rect',
        encoding: {
            x: {
                field: 'year',
                type: 'ordinal',
                title: 'Year',
            },
            y: {
                field: 'category',
                type: 'nominal',
                title: 'Player',
            },
            color: {
                field: 'hitting_rate',
                type: 'quantitative',
                title: 'Hit Rate',
                scale: { scheme: 'blues' },
            },
            tooltip: [
                { field: 'category', type: 'nominal' },
                { field: 'year', type: 'ordinal' },
                { field: 'hit', type: 'quantitative', title: 'Hits' },
                { field: 'miss', type: 'quantitative', title: 'Misses' },
            ],
        },
    };
}
