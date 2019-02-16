This is a collection of snippets that describe the expected behaviour of Xalgo
expressions. Both syntax and expected interpretation are described.

# REFINE

A new action type will be introduced to replace `MAP`, `FILTER` and `REDUCE`. It
is designed to be idempotent - it only creates *new* tables rather than
modifying *existing* tables (previous actions had in-place modified existing
tables). The `KEEP` action will also be eliminated by this change. Since `KEEP`
had been an action for preserve a copy of a table *before* performing an action
that would modify it in-place, the removal of in-place modification eliminates
the need for `KEEP`.

`REFINE` has this syntax:

```
REFINE <section>:<table> AS <new_table>
  FILTER <boolean expression>
  MAP <assignment expression>
  TAKE <row selection function>;
```
  
`FILTER` is used to *remove* rows from the computation *before* applying `MAP` assignments.

`MAP` is used to update or add column keys on a *per-row basis*.

`TAKE` is used to prune rows from the table *after* modifications have occurred.

Some examples will make this easier to understand. Consider this table (*a*):

type  | price | count
------|-------|------
apple | 2.00  | 1
apple | 8.00  | 4
orange| 12.00 | 3
orange| 4.00  | 1

## Filtered summation

If we want to compute the total cost of all items where more than one item has
been purchased, we could write:

```
REFINE table:a AS b
  FILTER count > 1
  MAP sum = add(sum, price)
  TAKE last(1);
```
  
This will filter out the items that have count < 1 before the computation
begins, given this table at the start of the computation:

type  | price | count
------|-------|------
apple | 8.00  | 4
orange| 12.00 | 3

Then, we will proceed on a row-by-row basis to accumulate the `sum` key into the
table, yielding this final table:

type  | price | count | sum
------|-------|-------|----
apple | 8.00  | 4     | 8.00
orange| 12.00 | 3     | 20.00

Once this has finished, the `TAKE` statement prunes the table to just the first
row from the last (`last(1)`) to yield:

type  | price | count | sum
------|-------|-------|----
orange| 12.00 | 3     | 20.00

While this final table looks odd, since this calculation is really only
interested in the final summation, we simply ignore the other columns and might
only consider `sum` in a subsequent `REVISE` action.

## Partitioned summation

Perhaps we are interested in totals related to the type of thing that was
purchased (`apple` or `orange`). The `REFINE` action syntax offers *no
mechanism* for partitioned refinements, therefore we need to refine the same
table twice:

```
REFINE table:a AS sum_apples
  FILTER type=='apple'
  MAP sum = add(sum, price)
  MAP total_count = add(total_count, count)
  TAKE last(1);
```

This proceeds similarly to the previous example yield the final table:

type  | price | count | sum   | total_count
------|-------|-------|-------|------
apple | 8.00  | 4     | 10.00 | 5

The case for `type=='orange'` would be similar:

```
REFINE table:a AS sum_oranges
  FILTER type=='orange'
  MAP sum = add(sum, price)
  MAP total_count = add(total_count, count)
  TAKE last(1);
```

# ARRANGE

`REFINE` offers the ability to update the data within the table, but it does not
offer the ability to algorithmically change the structure of the table (sorting,
ordering of row). This will be provided by the `ARRANGE` action.

For example, given:

type  | price | count
------|-------|------
apple | 2.00  | 1
apple | 8.00  | 4
orange| 12.00 | 3
orange| 4.00  | 1

We could sort based on the price:

```
ARRANGE table:a AS table:price_sorted
  USING sort(price, 'numeric', 'ascending');
```

This yields:

type  | price | count
------|-------|------
apple | 2.00  | 1
orange| 4.00  | 1
apple | 8.00  | 4
orange| 12.00 | 3

We can invert the table:

```
ARRANGE table:a AS table:price_sorted
  USING invert();
```

Yielding:

type  | price | count
------|-------|------
orange| 4.00  | 1
orange| 12.00 | 3
apple | 8.00  | 4
apple | 2.00  | 1

We can also shift the rows:

```
ARRANGE table:a AS table:price_sorted
  USING shift(2);
```

Yielding:

type  | price | count
------|-------|------
orange| 12.00 | 3
orange| 4.00  | 1
apple | 2.00  | 1
apple | 8.00  | 4

Or shift in reverse:

```
ARRANGE table:a AS table:price_sorted
  USING shift(-3);
```

Yielding:

type  | price | count
------|-------|------
apple | 8.00  | 4
orange| 12.00 | 3
orange| 4.00  | 1
apple | 2.00  | 1

