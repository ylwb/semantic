{-# LANGUAGE DataKinds, TemplateHaskell, TypeOperators #-}
module Language.Ruby.Syntax where

import Data.Functor.Union
import qualified Data.Syntax as Syntax
import Data.Syntax.Assignment
import qualified Data.Syntax.Comment as Comment
import qualified Data.Syntax.Declaration as Declaration
import qualified Data.Syntax.Expression as Expression
import qualified Data.Syntax.Literal as Literal
import qualified Data.Syntax.Statement as Statement
import Language.Haskell.TH hiding (location, Range(..))
import Prologue hiding (get, Location, optional, state, unless)
import Term
import Text.Parser.TreeSitter.Language
import Text.Parser.TreeSitter.Ruby

-- | The type of Ruby syntax.
type Syntax = Union Syntax'
type Syntax' =
  '[Comment.Comment
  , Declaration.Class
  , Declaration.Method
  , Expression.Not
  , Literal.Array
  , Literal.Boolean
  , Literal.Hash
  , Literal.Integer
  , Literal.String
  , Literal.Symbol
  , Statement.Break
  , Statement.Continue
  , Statement.If
  , Statement.Return
  , Statement.Yield
  , Syntax.Empty
  , Syntax.Identifier
  , []
  ]


-- | Statically-known rules corresponding to symbols in the grammar.
mkSymbolDatatype (mkName "Grammar") tree_sitter_ruby


-- | Assignment from AST in Ruby’s grammar onto a program in Ruby’s syntax.
assignment :: Assignment (Node Grammar) [Term Syntax Location]
assignment = symbol Program *> children (many declaration)

declaration :: Assignment (Node Grammar) (Term Syntax Location)
declaration = comment <|> class' <|> method

class' :: Assignment (Node Grammar) (Term Syntax Location)
class' = term <*  symbol Class
              <*> children (Declaration.Class <$> (constant <|> scopeResolution) <*> (superclass <|> pure []) <*> many declaration)
  where superclass = pure <$ symbol Superclass <*> children constant
        scopeResolution = symbol ScopeResolution *> children (constant <|> identifier)

constant :: Assignment (Node Grammar) (Term Syntax Location)
constant = term <*> (Syntax.Identifier <$ symbol Constant <*> source)

identifier :: Assignment (Node Grammar) (Term Syntax Location)
identifier = term <*> (Syntax.Identifier <$ symbol Identifier <*> source)

method :: Assignment (Node Grammar) (Term Syntax Location)
method = term <*  symbol Method
              <*> children (Declaration.Method <$> identifier <*> pure [] <*> (term <*> many statement))

statement :: Assignment (Node Grammar) (Term Syntax Location)
statement  =  exit Statement.Return Return
          <|> exit Statement.Yield Yield
          <|> exit Statement.Break Break
          <|> exit Statement.Continue Next
          <|> if'
          <|> ifModifier
          <|> unless
          <|> unlessModifier
          <|> literal
  where exit construct sym = term <*> (construct <$ symbol sym <*> children (optional (symbol ArgumentList *> children statement)))

comment :: Assignment (Node Grammar) (Term Syntax Location)
comment = term <*> (Comment.Comment <$ symbol Comment <*> source)

if' :: Assignment (Node Grammar) (Term Syntax Location)
if' = go If
  where go s = term <* symbol s <*> children (Statement.If <$> statement <*> (term <*> many statement) <*> optional (go Elsif <|> term <* symbol Else <*> children (many statement)))

ifModifier :: Assignment (Node Grammar) (Term Syntax Location)
ifModifier = term <* symbol IfModifier <*> children (flip Statement.If <$> statement <*> statement <*> (term <*> pure Syntax.Empty))

unless :: Assignment (Node Grammar) (Term Syntax Location)
unless = term <* symbol Unless <*> children (Statement.If <$> (term <*> (Expression.Not <$> statement)) <*> (term <*> many statement) <*> optional (term <* symbol Else <*> children (many statement)))

unlessModifier :: Assignment (Node Grammar) (Term Syntax Location)
unlessModifier = term <* symbol UnlessModifier <*> children (flip Statement.If <$> statement <*> (term <*> (Expression.Not <$> statement)) <*> (term <*> pure Syntax.Empty))

literal :: Assignment (Node Grammar) (Term Syntax Location)
literal  =  term <*> (Literal.true <$ symbol Language.Ruby.Syntax.True <* source)
        <|> term <*> (Literal.false <$ symbol Language.Ruby.Syntax.False <* source)
        <|> term <*> (Literal.Integer <$ symbol Language.Ruby.Syntax.Integer <*> source)

-- | Assignment of the current node’s annotation.
term :: InUnion Syntax' f => Assignment (Node grammar) (f (Term Syntax Location) -> Term Syntax Location)
term =  (\ a f -> cofree $ a :< inj f) <$> location

optional :: Assignment (Node Grammar) (Term Syntax Location) -> Assignment (Node Grammar) (Term Syntax Location)
optional a = a <|> term <*> pure Syntax.Empty


-- | Produce a list of identifiable subterms of a given term.
--
--   By “identifiable” we mean terms which have a user-assigned identifier associated with them, & which serve as a declaration rather than a reference; i.e. the declaration of a class or method or binding of a variable are all identifiable terms, but calling a named function or referencing a parameter is not.
identifiable :: Term Syntax a -> [Term Syntax a]
identifiable = para $ \ c@(_ :< union) -> case union of
  _ | Just Declaration.Class{} <- prj union -> cofree (fmap fst c) : foldMap snd union
  _ -> foldMap snd union
