function surprisal(p: number) {
  // unit determines the unit of information at which we measure surprisal
  // base 2 is the default and it measures information in bits
  return Math.log2(1 / p)
}

function entropy(p: number) {
  return p === 1 ? 0 : p * surprisal(p) + (1 - p) * surprisal(1 - p)
}

function crossEntropy(p: number, q: number) {
  return (p === 1 && q === 1) || (p === 0 && q === 0)
    ? 0
    : p * surprisal(q) + (1 - p) * surprisal(1 - q)
}

export default function relativeEntropy(p: number, q: number) {
  return crossEntropy(p, q) - entropy(p)
}
