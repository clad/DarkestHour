//==============================================================================
// Darklight Games (c) 2008-2016
//==============================================================================

class ArrayList_Object extends Object;

var array<Object> Items;

function Add(Object Item)
{
    Items[Items.Length] = Item;
}

function AddAtIndex(int Index, Object Item)
{
    Items.Insert(Index, 1);

    Items[Index] = Item;
}

function Clear()
{
    Items.Length = 0;
}

function bool Contains(Object Item)
{
    return IndexOf(Item) != -1;
}

function Object Get(int Index)
{
    return Items[Index];
}

function int IndexOf(Object Item)
{
    local int i;

    for (i = 0; i < Items.Length; ++i)
    {
        if (Items[i] == Item)
        {
            return i;
        }
    }

    return -1;
}

function bool IsEmpty()
{
    return Items.Length == 0;
}

function int LastIndexOf(Object Item)
{
    local int i;

    for (i = Items.Length - 1; i >= 0; --i)
    {
        if (Items[i] == Item)
        {
            return i;
        }
    }

    return -1;
}

function Remove(int Index)
{
    Items.Remove(Index, 1);
}

function RemoveRange(int FromIndex, int ToIndex)
{
    local int Count;

    Count = ToIndex - FromIndex + 1;

    Items.Remove(FromIndex, Count);
}

function Resize(int Length)
{
    Items.Length = Length;
}

function Set(int Index, Object Item)
{
    Items[Index] = Item;
}

function int Size()
{
    return Items.Length;
}

function array<Object> ToArray()
{
    return Items;
}

