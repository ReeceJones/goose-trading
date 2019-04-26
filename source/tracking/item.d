module tracking.item;

import tracking.market;

immutable string stattrakQSTR = "StatTrak™ ";

enum Condition : string
{
    FactoryNew = "Factory New",
    MinimalWear = "Minimal Wear",
    FieldTested = "Field-Tested",
    WellWorn = "Well-Worn",
    BattleScarred = "Battle-Scarred"
}

struct Item
{
    string name;
    Condition condition;
    bool stattrak;
}
