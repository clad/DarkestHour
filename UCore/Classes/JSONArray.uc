//==============================================================================
// Darklight Games (c) 2008-2016
//==============================================================================

class JSONArray extends JSONValue;

var ArrayList_JSONValue Values;

function int Size()
{
    return Values.Size();
}

function bool IsArray()
{
    return true;
}

function JSONArray AsArray()
{
    return self;
}

function string Encode()
{
    local int i;
    local array<string> Strings;

    if (Values != none)
    {
        for (i = 0; i < Values.Size(); ++i)
        {
            Log(Values.Get(i).Encode());

            Strings[Strings.Length] = Values.Get(i).Encode();
        }
    }

    return "[" $ class'UString'.static.Join(",", Strings) $ "]";
}

function Add(JSONValue Item)
{
    Values.Add(Item);
}

function AddAtIndex(int Index, JSONValue Item)
{
    Values.AddAtIndex(Index, Item);
}

function JSONValue Get(int Index)
{
    return Values.Get(Index);
}

static function JSONArray VCreate(vector V)
{
    local JSONArray A;

    A = new class'JSONArray';
    A.Values = new class'ArrayList_JSONValue';
    A.Add(class'JSONNumber'.static.FCreate(V.X));
    A.Add(class'JSONNumber'.static.FCreate(V.X));
    A.Add(class'JSONNumber'.static.FCreate(V.X));

    return A;
}
