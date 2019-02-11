// Maybe change the timestamp for tests to be time.now()?

module.exports = {
  test: {
    // FIX THESE NUMBERS
    privateSaleEnd: Math.floor(Date.now() / 1000 + (1200 *1)).toString(),
    preICOEnd: Math.floor(Date.now() / 1000 + (1200 * 2)).toString(),
    ico1End: Math.floor(Date.now() / 1000 + (1200 * 3)).toString(),
    ico2End: Math.floor(Date.now() / 1000 + (1200 * 4)).toString(),
    ico3End: Math.floor(Date.now() / 1000 + (1200 * 5 )).toString(),
    liveEnd: Math.floor(Date.now() / 1000 + (1200 * 6 )).toString(),
    // FIX THESE NUMBERS
    privateSaleCents: 5,
    preICOCents: 25,
    ico1Cents: 50,
    ico2Cents: 75,
    ico3Cents: 100,
    ethPrice: 11936
  },
  production: {
    privateSaleEnd: 1552608000,
    preICOEnd: 1556582400,
    ico1End: 1559260800,
    ico2End: 1561852800,
    ico3End: 1564444800,
    liveEnd: 1564444800,
    // FIX THESE NUMBERS
    privateSaleCents: 5,
    preICOCents: 25,
    ico1Cents: 50,
    ico2Cents: 75,
    ico3Cents: 100,
    ethPrice: 11936
  }
};
