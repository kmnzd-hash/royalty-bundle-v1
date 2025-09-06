const totalRevenue = sale.amount;
const splits = {
  creator: totalRevenue * (sale.creator_pct / 100),
  referrer: totalRevenue * (sale.referrer_pct / 100),
  ip_holder: totalRevenue * (sale.ip_holder_pct / 100),
};
