// This may look like C code, but it is really -*- C++ -*-
/* 
Copyright (C) 1988 Free Software Foundation
    written by Doug Lea (dl@rocky.oswego.edu)

This file is part of GNU CC.

GNU CC is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY.  No author or distributor
accepts responsibility to anyone for the consequences of using it
or for whether it serves any particular purpose or works at all,
unless he says so in writing.  Refer to the GNU CC General Public
License for full details.

Everyone is granted permission to copy, modify and redistribute
GNU CC, but only under the conditions described in the
GNU CC General Public License.   A copy of this license is
supposed to have been given to you along with GNU CC so you
can know your rights and responsibilities.  It should be in a
file named COPYING.  Among other things, the copyright notice
and this notice must be preserved on all copies.  
*/

#ifdef __GNUG__
#pragma implementation
#endif
#include "<T>.VHBag.h"

/* codes for status fields */

#define EMPTYCELL   0
#define VALIDCELL   1
#define DELETEDCELL 2


<T>VHBag::<T>VHBag(unsigned int sz)
{
  tab = new <T>[size = sz];
  status = new char[size];
  for (unsigned int i = 0; i < size; ++i) status[i] = EMPTYCELL;
  count = 0;
}
 
<T>VHBag::<T>VHBag(<T>VHBag& a)
{
  tab = new <T>[size = a.size];
  status = new char[size];
  for (unsigned int i = 0; i < size; ++i) status[i] = EMPTYCELL;
  count = 0;
  for (Pix p = a.first(); p; a.next(p)) add(a(p));
}


/* 
 * hashing method: double hash based on high bits of hash fct,
 * followed by linear probe. Can't do too much better if table
 * sizes not constrained to be prime.
*/


static inline unsigned int doublehashinc(unsigned int h, unsigned int s)
{
  unsigned int dh =  ((h / s) % s);
  return (dh > 1)? dh : 1;
}

Pix <T>VHBag::seek(<T&> key, Pix p)
{
  <T>* t = (<T>*) p;
  if (t == 0 || !<T>EQ(*t, key))
  {
    unsigned int hashval = <T>HASH(key);
    unsigned int h = hashval % size;
    for (unsigned int i = 0; i <= size; ++i)
    {
      if (status[h] == EMPTYCELL)
        return 0;
      else if (status[h] == VALIDCELL && <T>EQ(key, tab[h]))
        return Pix(&tab[h]);
      if (i == 0)
        h = (h + doublehashinc(hashval, size)) % size;
      else if (++h >= size)
        h -= size;
    }
    return 0;
  }
  else
  {
    int seent = 0;
    unsigned int hashval = <T>HASH(key);
    unsigned int h = hashval % size;
    for (unsigned int i = 0; i <= size; ++i)
    {
      if (status[h] == EMPTYCELL)
        return 0;
      else if (&tab[h] == t)
        seent = 1;
      else if (seent && status[h] == VALIDCELL && <T>EQ(key, tab[h]))
        return Pix(&tab[h]);
      if (i == 0)
        h = (h + doublehashinc(hashval, size)) % size;
      else if (++h >= size)
        h -= size;
    }
    return 0;
  }
}

int <T>VHBag::nof(<T&> item)
{
  int n = 0;
  unsigned int hashval = <T>HASH(item);
  unsigned int h = hashval % size;
  unsigned int firsth = size;
  for (unsigned int i = 0; i <= size; ++i)
  {
    if (status[h] == EMPTYCELL)
      return n;
    else if (h != firsth && status[h] == VALIDCELL && <T>EQ(item, tab[h]))
    {
      ++n;
      if (firsth >= size)
        firsth = h;
    }
    if (i == 0)
      h = (h + doublehashinc(hashval, size)) % size;
    else if (++h >= size)
      h -= size;
  }
  return n;
}


Pix <T>VHBag::add(<T&> item)
{
  if (size <= count + 1)
    resize();
  unsigned int bestspot = size;
  unsigned int hashval = <T>HASH(item);
  unsigned int h = hashval % size;
  for (unsigned int i = 0; i <= size; ++i)
  {
    if (status[h] == EMPTYCELL)
    {
      if (bestspot >= size) bestspot = h;
      tab[bestspot] = item;
      status[bestspot] = VALIDCELL;
      ++count;
      return Pix(&tab[bestspot]);
    }
    else if (status[h] == DELETEDCELL)
    {
      if (bestspot >= size) bestspot = h;
    }

    if (i == 0)
      h = (h + doublehashinc(hashval, size)) % size;
    else if (++h >= size)
      h -= size;
  }
  tab[bestspot] = item;
  status[bestspot] = VALIDCELL;
  ++count;
  return Pix(&tab[bestspot]);
}


void <T>VHBag::del(<T&> key)
{
  unsigned int hashval = <T>HASH(key);
  unsigned int h = hashval % size;
  for (unsigned int i = 0; i <= size; ++i)
  {
    if (status[h] == EMPTYCELL)
      return;
    else if (status[h] == VALIDCELL && <T>EQ(key, tab[h]))
    {
      status[h] = DELETEDCELL;
      --count;
      return;
    }
    if (i == 0)
      h = (h + doublehashinc(hashval, size)) % size;
    else if (++h >= size)
      h -= size;
  }
}

void <T>VHBag::remove(<T&> key)
{
  unsigned int hashval = <T>HASH(key);
  unsigned int h = hashval % size;
  for (unsigned int i = 0; i <= size; ++i)
  {
    if (status[h] == EMPTYCELL)
      return;
    else if (status[h] == VALIDCELL && <T>EQ(key, tab[h]))
    {
      status[h] = DELETEDCELL;
      --count;
    }
    if (i == 0)
      h = (h + doublehashinc(hashval, size)) % size;
    else if (++h >= size)
      h -= size;
  }
}

void <T>VHBag::clear()
{
  for (unsigned int i = 0; i < size; ++i) status[i] = EMPTYCELL;
  count = 0;
}

void <T>VHBag::resize(unsigned int newsize)
{
  if (newsize <= count)
  {
    newsize = DEFAULT_INITIAL_CAPACITY;
    while (newsize <= count) newsize <<= 1;
  }
  <T>* oldtab = tab;
  char* oldstatus = status;
  unsigned int oldsize = size;
  tab = new <T>[size = newsize];
  status = new char[size];
  for (unsigned int i = 0; i < size; ++i) status[i] = EMPTYCELL;
  count = 0;
  for (i = 0; i < oldsize; ++i) if (oldstatus[i] == VALIDCELL) add(oldtab[i]);
  delete [oldsize] oldtab;
  delete oldstatus;
}

Pix <T>VHBag::first()
{
  for (unsigned int pos = 0; pos < size; ++pos)
    if (status[pos] == VALIDCELL) return Pix(&tab[pos]);
  return 0;
}

void <T>VHBag::next(Pix& i)
{
  if (i == 0) return;
  unsigned int pos = ((unsigned)i - (unsigned)tab) / sizeof(<T>) + 1;
  for (; pos < size; ++pos)
    if (status[pos] == VALIDCELL)
    {
      i = Pix(&tab[pos]);
      return;
    }
  i = 0;
}

  
int <T>VHBag::OK()
{
  int v = tab != 0;
  v &= status != 0;
  int n = 0;
  for (unsigned int i = 0; i < size; ++i) 
  {
    if (status[i] == VALIDCELL) ++n;
    else if (status[i] != DELETEDCELL && status[i] != EMPTYCELL)
      v = 0;
  }
  v &= n == count;
  if (!v) error("invariant failure");
  return v;
}
