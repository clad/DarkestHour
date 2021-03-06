//==============================================================================
// Darklight Games (c) 2008-2016
//==============================================================================
// We will use insertion sort, since it doesn't require any recursive calls.
// Recursive calls kill performance because UnrealScript dynamic arrays are not
// passed by reference.
//
// TODO: When we get proper template capabilities, we can convert all of these
// to perform a quicksort on ArrayList<T> instead of array<T>.
//==============================================================================

class USort extends Object
    abstract;

static final function Sort(out array<Object> A, UComparator Comparator)
{
    local int i, j;

    for (i = 1; i < A.Length; ++i)
    {
        j = i;

        while (j > 0 && Comparator.CompareFunction(A[j - 1], A[j]))
        {
            class'UCore'.static.Swap(A[j], A[j + 1]);

            j -= 1;
        }
    }
}

static final function ISort(out array<int> A, UComparator Comparator)
{
    local int i, j;

    for (i = 1; i < A.Length; ++i)
    {
        j = i;

        while (j > 0 && A[j - 1] < A[j])
        {
            class'UCore'.static.ISwap(A[j], A[j + 1]);

            j -= 1;
        }
    }
}
