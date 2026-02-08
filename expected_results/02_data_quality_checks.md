## Output



```text

  table\_name   | rows

----------------+------

dim\_customer   |   12

dim\_product    |   12

fct\_order      |   14

fct\_order\_item |   29

fct\_payment    |   14

(5 rows)



 check\_name  | duplicate\_groups

--------------+------------------

dim\_customer |                0

dim\_product  |                0

fct\_order    |                0

fct\_payment  |                0

(4 rows)



null\_customer\_id | blank\_full\_name | blank\_email | null\_created\_at | blank\_country

------------------+-----------------+-------------+-----------------+---------------

               0 |               0 |           1 |               0 |             0

(1 row)



null\_product\_id | blank\_product\_name | blank\_category | null\_unit\_price

-----------------+--------------------+----------------+-----------------

              0 |                  0 |              0 |               0

(1 row)



null\_order\_id | null\_customer\_id | null\_order\_ts | blank\_order\_status | blank\_channel

---------------+------------------+---------------+--------------------+---------------

            0 |                0 |             0 |                  0 |             0

(1 row)



      check\_name        | rows

-------------------------+------

orders\_missing\_customer |    0

(1 row)



       check\_name         | rows

---------------------------+------

order\_items\_missing\_order |    0

(1 row)



        check\_name          | rows

-----------------------------+------

order\_items\_missing\_product |    0

(1 row)



      check\_name       | rows

------------------------+------

payments\_missing\_order |    0

(1 row)



       check\_name         | rows

---------------------------+------

negative\_or\_zero\_quantity |    0

(1 row)



         check\_name          | rows

------------------------------+------

negative\_unit\_price\_in\_items |    0

(1 row)



          check\_name            | rows

---------------------------------+------

negative\_unit\_price\_in\_products |    0

(1 row)



      check\_name       | rows

------------------------+------

invalid\_payment\_amount |    0

(1 row)



order\_id | items\_gross | paid\_amount | paid\_minus\_items

----------+-------------+-------------+------------------

    3012 |       23.40 |       23.49 |             0.09

    3001 |       15.45 |       15.45 |             0.00

    3002 |       14.55 |       14.55 |             0.00

    3003 |       19.99 |       19.99 |             0.00

    3004 |       12.75 |       12.75 |             0.00

    3005 |       21.49 |       21.49 |             0.00

    3006 |       42.97 |       42.97 |             0.00

    3007 |        8.80 |        8.80 |             0.00

    3008 |       57.98 |       57.98 |             0.00

    3009 |       17.40 |       17.40 |             0.00

    3010 |       23.00 |       23.00 |             0.00

    3011 |       12.35 |       12.35 |             0.00

    3013 |       28.98 |       28.98 |             0.00

    3014 |        7.80 |        7.80 |             0.00

(14 rows)



