# XAUUSD PRO V1 — MT5 Expert Advisor

EA starter សម្រាប់ MetaTrader 5 (MT5) ដែលរចនាឡើងសម្រាប់សាកល្បងលើយុទ្ធសាស្ត្រ XAUUSD។

## លក្ខណៈពិសេស
- EMA 20 / 50 / 200 សម្រាប់តម្រងទិសដៅ
- RSI(14) សម្រាប់ការបញ្ជាក់សញ្ញា
- ATR(14) សម្រាប់គណនា Stop Loss
- Take Profit តាម Risk/Reward ដែលកំណត់
- គណនាទំហំ lot តាមភាគរយហានិភ័យនៃ Equity
- ពិនិត្យ spread មុនពេលបើក order
- ប្រើ candle ដែលបានបិទរួច (shift 1) ដើម្បីកាត់បន្ថយសញ្ញាផ្លាស់ប្តូរនៅកណ្ដាល candle
- មិនបើក position ថ្មី ប្រសិនបើមាន position លើ symbol ដូចគ្នារួច

## ឯកសារសំខាន់
- `XAUUSD_PRO_V1_MT5.mq5` — source code របស់ EA

## របៀបដំឡើងក្នុង MT5
1. ទាញយក `XAUUSD_PRO_V1_MT5.mq5` ពី GitHub។
2. បើក MetaTrader 5 នៅលើកុំព្យូទ័រ ហើយចូល `File → Open Data Folder`។
3. បើកថត `MQL5/Experts/` ហើយដាក់ឯកសារ `.mq5` នៅក្នុងនោះ។
4. បើក MetaEditor រួច Compile ឯកសារ។
5. នៅ MT5 សូម Refresh ផ្នែក Navigator → Expert Advisors ហើយដាក់ EA លើ chart XAUUSD។
6. សាកល្បងក្នុង Strategy Tester និងគណនី Demo ជាមុនសិន។

> ចំណាំ៖ ការបង្កើត/Compile EA ជាធម្មតាត្រូវការ MT5 Desktop និង MetaEditor។ ការដាក់ source code លើ GitHub មិនមានន័យថា EA បានដំណើរការ ឬបានដំឡើងលើ MT5 ទេ។

## ការកំណត់ដំបូង
- Timeframe លំនាំដើម៖ M5
- Risk per trade លំនាំដើម៖ 0.5% នៃ Equity
- Stop Loss៖ 2 × ATR
- Take Profit៖ Risk/Reward 1.5:1
- RSI BUY threshold៖ 52
- RSI SELL threshold៖ 48
- Max spread៖ 80 broker points (ត្រូវកែតាម broker និង symbol)

អាចកែ settings នៅក្នុង EA Inputs។ ឈ្មោះ symbol មាសអាចខុសគ្នាតាម broker ដូចជា `XAUUSD`, `XAUUSD.a` ឬឈ្មោះផ្សេងទៀត។ ប្រសិនបើចាំបាច់ សូមបញ្ចូលឈ្មោះត្រឹមត្រូវក្នុង `InpSymbol`។

## ហានិភ័យ និងការទទួលខុសត្រូវ
នេះជាគំរូ EA សម្រាប់ការអភិវឌ្ឍ និងសាកល្បង មិនមែនជាការធានាប្រាក់ចំណេញ ឬជាដំបូន្មានហិរញ្ញវត្ថុទេ។ ការជួញដូរមាសអាចបណ្ដាលឱ្យខាតបង់។ សូមសាកល្បងលើ Demo និងពិនិត្យលទ្ធផល/ការគណនា lot ជាមួយ broker របស់អ្នក មុនប្រើប្រាស់ជាក់ស្តែង។ អ្នកប្រើទទួលខុសត្រូវលើការកំណត់ និងការប្រើប្រាស់ EA។
