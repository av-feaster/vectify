/** Conservative SVGO for icons (SVGO 3: removeViewBox is not inside preset-default). */
export default {
  plugins: [
    {
      name: "preset-default",
      params: {
        overrides: {
          mergePaths: false,
          convertShapeToPath: false,
          convertPathData: {
            floatPrecision: 4,
            transformPrecision: 4,
          },
          cleanupNumericValues: { floatPrecision: 4 },
        },
      },
    },
    { name: "removeViewBox", active: false },
  ],
};
